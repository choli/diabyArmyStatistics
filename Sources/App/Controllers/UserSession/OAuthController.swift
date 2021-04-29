import Vapor

struct OAuthController: RouteCollection {

    let consumerKey: String
    let consumerSecret: String

    init() {
        guard let consumerKey = Environment.get("TWITTER_CONSUMER_KEY"), let consumerSecret = Environment.get("TWITTER_CONSUMER_SECRET")
        else { fatalError("Consumer key or secret not set properly") }
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }

    func boot(routes: RoutesBuilder) throws {

        routes.get("twitter") { req -> String in
            if let screenName = req.session.data["screenName"] {
                return "Dein Twitter handle ist \(screenName)"
            } else {
                return "Du bist nicht eingeloggt."
            }
        }

        routes.get("status") { req -> EventLoopFuture<Response> in
            guard RequestAccessTokenResponse.sessionToken(in: req) != nil
            else {
                req.session.data["initialRequest"] = "status"
                return req.eventLoop.future(req.redirect(to: "/requestLogin"))
            }

            return req.eventLoop.future(req.redirect(to: "/verifyCredentials"))
        }

        routes.get("verifyCredentials") { req -> EventLoopFuture<VerificationObject> in
            guard let accessToken = RequestAccessTokenResponse.sessionToken(in: req)
            else {
                fatalError("Shouldn't access directly! Else this check should be done")
            }

            let request = (url: "https://api.twitter.com/1.1/account/verify_credentials.json", httpMethod: "GET")

            var params: [String: Any] = [
                "oauth_consumer_key" : consumerKey,
                "oauth_token" : accessToken.accessToken,
                "oauth_nonce" : UUID().uuidString, // nonce can be any 32-bit string made up of random ASCII values
                "oauth_signature_method" : "HMAC-SHA256",
                "oauth_timestamp" : String(Int(Date().timeIntervalSince1970)),
                "oauth_version" : "1.0"
            ]
            // Build the OAuth Signature from Parameters
            params["oauth_signature"] = oauthSignature(httpMethod: request.httpMethod, url: request.url,
                                                       params: params, consumerSecret: consumerSecret,
                                                       oauthTokenSecret: accessToken.accessTokenSecret)

            // Once OAuth Signature is included in our parameters, build the authorization header
            let authHeader = authorizationHeader(params: params)
            let url = URI(string: request.url)

            return req.client.get(url) { req in
                req.headers.add(name: "Authorization", value: authHeader)
            }.flatMapThrowing { res in
                return try res.content.decode(VerificationObject.self)
            }
        }

        struct VerificationObject: Content {
            let name: String
        }

        // MARK: - Login flow

        routes.get("requestLogin") { req -> EventLoopFuture<Response> in
            // Clear session when a user requests a new login
            clearSession(req.session)

            let requestTokenELF = try requestOAuthToken(req: req)
            return requestTokenELF.map { requestToken in
                req.session.data["oauthToken"] = requestToken.oauthToken
                req.session.data["oauthTokenSecret"] = requestToken.oauthTokenSecret
                return req.redirect(to: "https://api.twitter.com/oauth/authenticate?oauth_token=\(requestToken.oauthToken)")
            }
        }

        routes.get("oauthCallback") { req -> EventLoopFuture<Response> in
            let authRes = try req.query.decode(RequestOAuthAuthenticationResponse.self)

            guard let oauthToken = req.session.data["oauthToken"], oauthToken == authRes.oauth_token, let auth_token_secret = req.session.data["oauthTokenSecret"]
            else { throw HTTPClientError.cancelled }

            let input = RequestAccessTokenInput(requestToken: authRes.oauth_token,
                                                requestTokenSecret: auth_token_secret,
                                                oauthVerifier: authRes.oauth_verifier)
            let accessTokenELF = try requestAccessToken(req: req, args: input)
            return accessTokenELF.map { accessToken in
                req.session.data["accessToken"] = accessToken.accessToken
                req.session.data["accessTokenSecret"] = accessToken.accessTokenSecret
                req.session.data["userId"] = accessToken.userId
                req.session.data["screenName"] = accessToken.screenName
                req.session.data["oauthToken"] = nil
                req.session.data["oauthTokenSecret"] = nil

                if let initialRequest = req.session.data["initialRequest"] {
                    req.session.data["initialRequest"] = nil
                    return req.redirect(to: initialRequest)
                } else {
                    return req.redirect(to: "/")
                }
            }
        }
    }

    // MARK: - Session handling

    private func clearSession(_ session: Session) {
        let keysToClean = [
            "oauthToken",
            "oauthTokenSecret",
            "userId",
            "screenName",
            "accessToken",
            "accessTokenSecret"
        ]

        keysToClean.forEach {
            session.data[$0] = nil
        }
    }

    // MARK: - request methods

    private func requestOAuthToken(req: Request) throws -> EventLoopFuture<RequestOAuthTokenResponse> {

        let request = (url: "https://api.twitter.com/oauth/request_token", httpMethod: "POST")
        let callback = "https://diabyarmy.de/oauthCallback"

        var params: [String: Any] = [
            "oauth_callback" : callback,
            "oauth_consumer_key" : consumerKey,
            "oauth_nonce" : UUID().uuidString, // nonce can be any 32-bit string made up of random ASCII values
            "oauth_signature_method" : "HMAC-SHA256",
            "oauth_timestamp" : String(Int(Date().timeIntervalSince1970)),
            "oauth_version" : "1.0"
        ]
        // Build the OAuth Signature from Parameters
        params["oauth_signature"] = oauthSignature(httpMethod: request.httpMethod, url: request.url,
                                                   params: params, consumerSecret: consumerSecret)

        // Once OAuth Signature is included in our parameters, build the authorization header
        let authHeader = authorizationHeader(params: params)
        let url = URI(string: request.url)

        return req.client.post(url) { req in
            req.headers.add(name: "Authorization", value: authHeader)
        }.flatMapThrowing { res in
            guard let body = res.body, let string = body.getString(at: body.readerIndex, length: body.capacity)
            else { throw HTTPClientError.cancelled }

            let attributes = string.urlQueryStringParameters

            guard let token = attributes["oauth_token"],
                  let tokenSecret = attributes["oauth_token_secret"],
                  let callbackConfirmed = attributes["oauth_callback_confirmed"]
            else { throw HTTPClientError.cancelled }

            return RequestOAuthTokenResponse(oauthToken: token,
                                             oauthTokenSecret: tokenSecret,
                                             oauthCallbackConfirmed: callbackConfirmed)
        }
    }


    private func requestAccessToken(req: Request, args: RequestAccessTokenInput) throws -> EventLoopFuture<RequestAccessTokenResponse> {

        let request = (url: "https://api.twitter.com/oauth/access_token", httpMethod: "POST")

        var params: [String: Any] = [
            "oauth_token" : args.requestToken,
            "oauth_verifier" : args.oauthVerifier,
            "oauth_consumer_key" : consumerKey,
            "oauth_nonce" : UUID().uuidString, // nonce can be any 32-bit string made up of random ASCII values
            "oauth_signature_method" : "HMAC-SHA256",
            "oauth_timestamp" : String(Int(Date().timeIntervalSince1970)),
            "oauth_version" : "1.0"
        ]

        // Build the OAuth Signature from Parameters
        params["oauth_signature"] = oauthSignature(httpMethod: request.httpMethod, url: request.url,
                                                   params: params, consumerSecret: consumerSecret,
                                                   oauthTokenSecret: args.requestTokenSecret)

        // Once OAuth Signature is included in our parameters, build the authorization header
        let authHeader = authorizationHeader(params: params)
        let url = URI(string: request.url)

        return req.client.post(url) { req in
            req.headers.add(name: "Authorization", value: authHeader)
        }.flatMapThrowing { res in
            guard let body = res.body, let string = body.getString(at: body.readerIndex, length: body.capacity)
            else { throw HTTPClientError.cancelled }

            let attributes = string.urlQueryStringParameters

            guard let accessToken = attributes["oauth_token"],
                  let accessTokenSecret = attributes["oauth_token_secret"],
                  let userId = attributes["user_id"],
                  let screenName = attributes["screen_name"]
            else { throw HTTPClientError.cancelled }

            return RequestAccessTokenResponse(accessToken: accessToken,
                                              accessTokenSecret: accessTokenSecret,
                                              userId: userId,
                                              screenName: screenName)
        }
    }

    // MARK: - Helper methods

    private func authorizationHeader(params: [String: Any]) -> String {
        var parts: [String] = []
        for param in params {
            let key = param.key.urlEncoded
            let val = "\(param.value)".urlEncoded
            parts.append("\(key)=\"\(val)\"")
        }
        return "OAuth " + parts.sorted().joined(separator: ", ")
    }

    private func signatureKey(_ consumerSecret: String,_ oauthTokenSecret: String?) -> String {

        guard let oauthSecret = oauthTokenSecret?.urlEncoded
        else { return consumerSecret.urlEncoded+"&" }

        return consumerSecret.urlEncoded+"&"+oauthSecret
    }

    private func signatureParameterString(params: [String: Any]) -> String {
        var result: [String] = []
        for param in params {
            let key = param.key.urlEncoded
            let val = "\(param.value)".urlEncoded
            result.append("\(key)=\(val)")
        }
        return result.sorted().joined(separator: "&")
    }

    private func signatureBaseString(_ httpMethod: String = "POST",_ url: String, _ params: [String:Any]) -> String {

        let parameterString = signatureParameterString(params: params)
        return httpMethod + "&" + url.urlEncoded + "&" + parameterString.urlEncoded

    }

    private func hmac_sha1(signingKey: String, signatureBase: String) -> String {
        // HMAC-SHA1 hashing algorithm returned as a base64 encoded string
        guard let keyArray = signingKey.data(using: .utf8), let signature = signatureBase.data(using: .utf8)
        else {
            assertionFailure("There is no reason for this not to work")
            return ""
        }

        let key = SymmetricKey(data: keyArray)
        let digest = Array(HMAC<SHA256>.authenticationCode(for: signature, using: key))
        let data = Data(digest)
        return data.base64EncodedString()
    }

    private func oauthSignature(httpMethod: String = "POST", url: String, params: [String: Any], consumerSecret: String, oauthTokenSecret: String? = nil) -> String {
        let signingKey = signatureKey(consumerSecret, oauthTokenSecret)
        let signatureBase = signatureBaseString(httpMethod, url, params)
        return hmac_sha1(signingKey: signingKey, signatureBase: signatureBase)
    }
}

private extension String {
    var urlEncoded: String {
        var charset: CharacterSet = .urlQueryAllowed
        charset.remove(charactersIn: "\n:#/?@!$&'()*+,;=")
        return self.addingPercentEncoding(withAllowedCharacters: charset)!
    }

    var urlQueryStringParameters: Dictionary<String, String> {
        // breaks apart query string into a dictionary of values
        var params = [String: String]()
        let items = self.split(separator: "&")
        for item in items {
            let combo = item.split(separator: "=")
            if combo.count == 2 {
                let key = "\(combo[0])"
                let val = "\(combo[1])"
                params[key] = val
            }
        }
        return params
    }
}
