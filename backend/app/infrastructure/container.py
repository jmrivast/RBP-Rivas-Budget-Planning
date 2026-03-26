from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.use_cases import (
    AuthUseCases,
    BackupUseCases,
    CategoriesUseCases,
    DashboardUseCase,
    DebtsUseCases,
    ExpensesUseCases,
    ExportUseCases,
    FixedPaymentsUseCases,
    IncomeUseCases,
    LoansUseCases,
    PersonalDebtsUseCases,
    SavingsUseCases,
    SettingsUseCases,
    SubscriptionUseCases,
)
from backend.app.infrastructure.adapters import AuthServiceAdapter, FinanceServiceAdapter
from backend.repositories.backup_repo import BackupRepository
from backend.repositories.subscription_repo import SubscriptionRepository
from backend.services.auth_service import AuthService
from backend.services.backup_service import BackupService
from backend.services.export_service import ExportService
from backend.services.finance_service import FinanceService
from backend.services.subscription_service import SubscriptionService


@dataclass(slots=True)
class FinanceUseCases:
    dashboard: DashboardUseCase
    categories: CategoriesUseCases
    expenses: ExpensesUseCases
    fixed_payments: FixedPaymentsUseCases
    income: IncomeUseCases
    loans: LoansUseCases
    debts: DebtsUseCases
    personal_debts: PersonalDebtsUseCases
    savings: SavingsUseCases
    settings: SettingsUseCases


class Container:
    """Simple dependency container for FastAPI wiring."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    def _auth_service(self) -> AuthService:
        return AuthService(self.session)

    def _finance_service(self, user_id: int) -> FinanceService:
        return FinanceService(self.session, user_id)

    def _backup_repo(self) -> BackupRepository:
        return BackupRepository(self.session)

    def _backup_service(self) -> BackupService:
        return BackupService(self._backup_repo())

    def _export_service(self, user_id: int) -> ExportService:
        return ExportService(self._finance_service(user_id))

    def auth_use_cases(self) -> AuthUseCases:
        auth_port = AuthServiceAdapter(self._auth_service())
        return AuthUseCases(auth=auth_port)

    def finance_use_cases(self, user_id: int) -> FinanceUseCases:
        finance_port = FinanceServiceAdapter(self._finance_service(user_id))
        return FinanceUseCases(
            dashboard=DashboardUseCase(finance=finance_port),
            categories=CategoriesUseCases(finance=finance_port),
            expenses=ExpensesUseCases(finance=finance_port),
            fixed_payments=FixedPaymentsUseCases(finance=finance_port),
            income=IncomeUseCases(finance=finance_port),
            loans=LoansUseCases(finance=finance_port),
            debts=DebtsUseCases(finance=finance_port),
            personal_debts=PersonalDebtsUseCases(finance=finance_port),
            savings=SavingsUseCases(finance=finance_port),
            settings=SettingsUseCases(finance=finance_port),
        )

    def export_use_cases(self, user_id: int) -> ExportUseCases:
        return ExportUseCases(export=self._export_service(user_id))

    def backup_use_cases(self) -> BackupUseCases:
        backup_repo = self._backup_repo()
        return BackupUseCases(backup=BackupService(backup_repo), backup_repo=backup_repo)

    def subscription_use_cases(self) -> SubscriptionUseCases:
        return SubscriptionUseCases(subscription=SubscriptionService(SubscriptionRepository(self.session)))


def build_container(session: AsyncSession) -> Container:
    return Container(session)
