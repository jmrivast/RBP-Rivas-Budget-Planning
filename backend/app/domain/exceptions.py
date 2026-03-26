class DomainError(Exception):
    """Base domain exception."""


class ValidationFailure(DomainError):
    """Raised when business validation fails."""


class NotFound(DomainError):
    """Raised when a requested resource does not exist."""


class AuthFailure(DomainError):
    """Raised when auth credentials/session are invalid."""

