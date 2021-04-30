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
    var encryptionKey: Data? {
        guard let sessionKey = Environment.get("SESSION_ENCRYPTION_KEY") else { return nil }
        return sessionKey.data(using: .utf8)
    }

    func stringForKey(_ key: DASessionKeys) -> String? {
        guard let keyData = encryptionKey else {
            assertionFailure("Key missing?")
            return nil
        }

        let encKey = SymmetricKey(data: keyData)
        guard let base64String = data[key.rawValue],
              let base64Decoded = Data(base64Encoded: base64String),
              let sealedBox = try? AES.GCM.SealedBox(combined: base64Decoded),
              let valueData = try? AES.GCM.open(sealedBox, using: encKey)
        else { return nil }

        return String(decoding: valueData, as: UTF8.self)
    }

    func setValue(_ value: String?, for key: DASessionKeys) {
        guard let keyData = encryptionKey else {
            assertionFailure("Key missing?")
            return
        }

        let encKey = SymmetricKey(data: keyData)

        guard let value = value, let valueData = value.data(using: .utf8)
        else {
            data[key.rawValue] = nil
            return
        }
        let sealedBox = try! AES.GCM.seal(valueData, using: encKey)
        let sealedString = sealedBox.combined!.base64EncodedString()

        data[key.rawValue] = sealedString
    }
}

