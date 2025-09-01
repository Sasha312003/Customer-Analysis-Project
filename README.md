# Customer Analysis Project

Мета: Аналіз продажів та поведінки клієнтів за даними онлайн-ритейлу.

## Інструменти
- SQL (Google BigQuery)
- Tableau
- Python (pandas, matplotlib)

## Основні метрики та показники
- Загальна виручка (Revenue)
- Кількість замовлень
- Середній чек
- Кількість унікальних клієнтів
- Top-10 клієнтів за доходом
- Когортний аналіз та Retention
- Revenue по місяцях (% від загальної виручки)

## Візуалізації
- Overview Dashboard: KPI tiles + місячні продажі
- Customer Analysis: Top-10 клієнтів + Heatmap retention
- Revenue trends: Line chart по місяцях

## Структура проекту
Customer_Analysis_Project/
│

├─ README.md

├─ data/ ← приклад даних для відтворення проекту

│ └─ sample_data.csv

├─ Tableau/

│ └─ Customer_Analysis.twbx

├─ SQL/

│ └─ queries.sql

├─ Python/

│ └─ revenue_analysis.ipynb



## SQL-запити
Всі запити, які використовувались для підготовки даних, знаходяться у `SQL/queries.sql`.

## Tableau
Повний workbook з усіма листами та дашбордами знаходиться у `Tableau/Customer_Analysis.twbx`.

## Python
Додатковий аналіз (Revenue trends, retention % calculation) збережено в `Python/revenue_analysis.ipynb`.


