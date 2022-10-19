import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';

T withAuthentication<T>(Authentication authentication, T Function() body) =>
    runZoned(
      body,
      zoneValues: {
        #_authentication: authentication,
      },
    );

Authentication? get currentAuthentication =>
    Zone.current[#_authentication] as Authentication?;

class Authentication {
  Authentication({
    this.token,
    this.isAuthenticated = false,
  });

  factory Authentication.unauthenticated() => Authentication();

  final AuthenticationToken? token;
  final bool isAuthenticated;

  Authentication copyWith({
    bool? isAuthenticated,
  }) =>
      Authentication(
        token: token,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

abstract class AuthenticationToken {}

class AuthenticationSecret extends AuthenticationToken {
  AuthenticationSecret(this.secret);

  final String secret;
}

// ignore: one_member_abstracts
abstract class AuthenticationProvider {
  Future<Authentication> authenticate(Request request);
}

// ignore: one_member_abstracts
abstract class AuthenticationResolver {
  Future<Authentication?> authenticate(Request request);
}

// ignore: one_member_abstracts
abstract class Authorizer {
  Future<bool> authorize(Authentication authentication);
}

class DelegatingAuthenticationProvider extends AuthenticationProvider {
  DelegatingAuthenticationProvider({
    required Iterable<AuthenticationResolver> resolvers,
    required Iterable<Authorizer> authorizers,
  })  : _resolvers = List.of(resolvers),
        _authorizers = List.of(authorizers);

  final List<AuthenticationResolver> _resolvers;
  final List<Authorizer> _authorizers;

  @override
  Future<Authentication> authenticate(Request request) async {
    final authentication = await _resolveAuthentication(request);
    return _authorizer(authentication);
  }

  Future<Authentication> _resolveAuthentication(Request request) async {
    for (final resolver in _resolvers) {
      final authentication = await resolver.authenticate(request);
      if (authentication != null) {
        return authentication;
      }
    }
    return Authentication.unauthenticated();
  }

  Future<Authentication> _authorizer(Authentication authentication) async {
    for (final authorizer in _authorizers) {
      final isAuthorized = await authorizer.authorize(authentication);
      if (isAuthorized) {
        return authentication.copyWith(isAuthenticated: true);
      }
    }
    return authentication;
  }
}

class SecretAuthenticationResolver extends AuthenticationResolver {
  static const authorizationHeaderPrefix = 'Bearer secret:';

  @override
  Future<Authentication?> authenticate(Request request) async {
    final authorizationHeader =
        request.headers[HttpHeaders.authorizationHeader];

    if (authorizationHeader == null ||
        !authorizationHeader.startsWith(authorizationHeaderPrefix)) {
      return null;
    }

    final secret =
        authorizationHeader.substring(authorizationHeaderPrefix.length);
    final token = AuthenticationSecret(secret);

    return Authentication(token: token);
  }
}

class SecretsAuthorizer extends Authorizer {
  SecretsAuthorizer(this.secrets);

  final List<String> secrets;

  @override
  Future<bool> authorize(Authentication authentication) async {
    final token = authentication.token;
    if (token is AuthenticationSecret) {
      return secrets.contains(token.secret);
    }
    return false;
  }
}
