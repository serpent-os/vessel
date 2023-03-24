/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.rest.pairing
 *
 * Pairing API for Vessel
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module vessel.rest.pairing;

public import moss.service.interfaces.endpoints;
import moss.service.context;
import moss.service.models;
import moss.service.tokens;
import vibe.d;

/** 
 * Manages incoming enrolment requests from Summit only.
 */
public final class VesselPairingService : ServiceEnrolmentAPI
{
    @disable this();

    mixin AppAuthenticatorContext;

    /** 
     * 
     * Params:
     *   context = global shared context
     */
    @noRoute this(ServiceContext context) @safe
    {
        this.context = context;
    }

    override void enrol(ServiceEnrolmentRequest request) @safe
    {
        /* Grab the token itself. */
        Token tk = Token.decode(request.issueToken).tryMatch!((Token tk) => tk);
        enforceHTTP(context.tokenManager.verify(tk, request.issuer.publicKey),
                HTTPStatus.forbidden, "Fraudulent packet");
        enforceHTTP(request.role == EnrolmentRole.RepositoryManager,
                HTTPStatus.methodNotAllowed, "Vessel only supports RepositoryManager role");
        enforceHTTP(request.issuer.role == EnrolmentRole.Hub,
                HTTPStatus.methodNotAllowed, "Vessel can only be paired with Summit");
        enforceHTTP(tk.payload.purpose == TokenPurpose.Authorization,
                HTTPStatus.forbidden, "enrol(): Require an Authorization token");

        logInfo(format!"Got a pairing request: %s"(request));
        SummitEndpoint endpoint;
        endpoint.status = EndpointStatus.AwaitingAcceptance;
        endpoint.id = request.issuer.publicKey;
        endpoint.hostAddress = request.issuer.url;
        endpoint.publicKey = request.issuer.publicKey;
        endpoint.bearerToken = request.issueToken;
        immutable err = context.appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    override VisibleEndpoint[] enumerate() @safe
    {
        return null;
    }

    override void accept(ServiceEnrolmentRequest request, NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.methodNotAllowed,
                "accept(): Vessel doesn't support requests");
    }

    override void decline(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.methodNotAllowed,
                "decline(): Vessel doesn't support requests");
    }

    override void leave(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "leave(): Not yet implemented");
    }

    /** 
     * Refresh the API token for the given connection only while the bearer token is still vali
     *
     * Params:
     *   token = The current API token
     * Returns: A newly allocated API token
     */
    override string refreshToken(NullableToken token) @safe
    {
        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        TokenPayload payload;
        payload.iss = "vessel";
        payload.sub = token.payload.sub;
        payload.aud = token.payload.aud;
        payload.admin = token.payload.admin;
        payload.uid = token.payload.uid;
        payload.act = token.payload.act;
        Token refreshedToken = context.tokenManager.createAPIToken(payload);
        return context.tokenManager.signToken(refreshedToken).tryMatch!((string s) => s);
    }

    override string refreshIssueToken(NullableToken token) @safe
    {
        string newToken;

        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        context.accountManager.getUser(token.payload.uid).match!((Account account) {
            TokenPayload payload;
            payload.iss = "vessel";
            payload.sub = token.payload.sub;
            payload.aud = token.payload.aud;
            payload.admin = context.accountManager.accountInGroup(account.id,
                BuiltinGroups.Admin).tryMatch!((bool b) => b);
            payload.uid = account.id;
            payload.act = account.type;
            Token refreshedToken = context.tokenManager.createBearerToken(payload);
            newToken = context.tokenManager.signToken(refreshedToken).tryMatch!((string s) => s);
            BearerToken bt;
            bt.rawToken = newToken;
            bt.id = account.id;
            bt.expiryUTC = refreshedToken.payload.exp;
            auto err = context.accountManager.setBearerToken(account, bt);
            enforceHTTP(err.isNull, HTTPStatus.forbidden, err.message);
        }, (DatabaseError err) {
            throw new HTTPStatusException(HTTPStatus.forbidden, err.message);
        });
        return newToken;
    }

private:

    ServiceContext context;
}
