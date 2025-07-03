// login exceptions 
class UserNotFoundAuthException implements Exception {}

class WrongPasswordAuthException implements Exception {}

class WrongEmailOrPasswordExcepion implements Exception {}

//register exceptions
class WeakPasswordAuthException implements Exception {}

class EmailAleadyInUsedAuthException implements Exception {}

class InvalidEmailAuthException implements Exception {}

//generic exceptions
class GenericAuthException implements Exception {}
class UserNotLoggedInAuthException implements Exception {}