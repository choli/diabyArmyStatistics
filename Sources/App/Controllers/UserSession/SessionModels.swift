import Vapor

struct RequestOAuthTokenResponse {
    let oauthToken: String
    let oauthTokenSecret: String
    let oauthCallbackConfirmed: String
}

struct RequestOAuthAuthenticationResponse: Content {
    let oauth_token: String
    let oauth_verifier: String
}

struct RequestAccessTokenInput {
    let requestToken: String // = RequestOAuthTokenResponse.oauthToken
    let requestTokenSecret: String // = RequestOAuthTokenResponse.oauthTokenSecret
    let oauthVerifier: String
}

struct RequestAccessTokenResponse {
    let accessToken: String
    let accessTokenSecret: String
    let userId: String
    let screenName: String

    static func sessionToken(in req: Request) -> RequestAccessTokenResponse? {
        guard let accessToken = req.session.stringForKey(.accessToken),
              let accessTokenSecret = req.session.stringForKey(.accessTokenSecret),
              let userId = req.session.stringForKey(.userId),
              let screenName = req.session.stringForKey(.screenName)
        else { return nil }

        return RequestAccessTokenResponse(accessToken: accessToken,
                                   accessTokenSecret: accessTokenSecret,
                                   userId: userId,
                                   screenName: screenName)
    }
}

enum DASessionKeys: String {
    case oauthToken
    case oauthTokenSecret

    case accessToken
    case accessTokenSecret
    case userId
    case screenName
    case initialRequest
}

extension Session {
    func stringForKey(_ key: DASessionKeys) -> String? {
        self.data[key.rawValue]
    }

    func setValue(_ value: String?, for key: DASessionKeys) {
        self.data[key.rawValue] = value
    }
}

