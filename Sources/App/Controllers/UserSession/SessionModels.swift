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
        guard let accessToken = req.session.data["accessToken"],
        let accessTokenSecret = req.session.data["accessTokenSecret"],
        let userId = req.session.data["userId"],
        let screenName = req.session.data["screenName"]
        else { return nil }

        return RequestAccessTokenResponse(accessToken: accessToken,
                                   accessTokenSecret: accessTokenSecret,
                                   userId: userId,
                                   screenName: screenName)
    }
}

