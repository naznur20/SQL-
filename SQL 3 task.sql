-- возрастные группы клиентов с шагом 10 лет и отдельно клиентов, 
-- у которых нет данной информации, 
-- с параметрами сумма и количество операций за весь период, 
-- и поквартально - средние показатели и %.


WITH RawData AS (
    -- Шаг 1: Объединяем таблицы, очищаем данные и делим клиентов на группы по 10 лет
    SELECT 
        t.Id_check,
        t.Sum_payment,
        -- Формируем квартал в формате 'YYYY-Q' (например, '2015-Q2')
        CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS Quarter_Period,
        CASE 
            WHEN c.AGE IS NULL OR c.AGE = '' THEN 'Нет данных'
            WHEN c.AGE BETWEEN 0 AND 9   THEN '0-9 лет'
            WHEN c.AGE BETWEEN 10 AND 19 THEN '10-19 лет'
            WHEN c.AGE BETWEEN 20 AND 29 THEN '20-29 лет'
            WHEN c.AGE BETWEEN 30 AND 39 THEN '30-39 лет'
            WHEN c.AGE BETWEEN 40 AND 49 THEN '40-49 лет'
            WHEN c.AGE BETWEEN 50 AND 59 THEN '50-59 лет'
            WHEN c.AGE BETWEEN 60 AND 69 THEN '60-69 лет'
            WHEN c.AGE BETWEEN 70 AND 79 THEN '70-79 лет'
            ELSE '80+ лет'
        END AS Age_Group
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
QuarterlyTotals AS (
    -- Шаг 2: Считаем общие итоги по каждому кварталу для расчета долей (%)
    SELECT 
        Quarter_Period,
        COUNT(*) AS Total_Ops_Quarter,
        SUM(Sum_payment) AS Total_Sum_Quarter
    FROM RawData
    GROUP BY Quarter_Period
)
-- Шаг 3: Собираем финальную статистику за весь период и поквартально
SELECT 
    r.Age_Group AS `Возрастная группа`,
    r.Quarter_Period AS `Квартал`,
    
    -- 📊 ПОКАЗАТЕЛИ ЗА ВЕСЬ ПЕРИОД И ПОКВАРТАЛЬНО (ФАКТ)
    COUNT(*) AS `Количество операций`,
    ROUND(SUM(r.Sum_payment), 2) AS `Сумма операций`,
    
    -- 📈 ПОКВАРТАЛЬНЫЕ СРЕДНИЕ ПОКАЗАТЕЛИ
    -- Средний чек в квартале = Сумма за квартал / Количество уникальных чеков группы за квартал
    ROUND(SUM(r.Sum_payment) / COUNT(DISTINCT r.Id_check), 2) AS `Средний чек за квартал`,
    -- Средняя сумма на одну операцию группы
    ROUND(AVG(r.Sum_payment), 2) AS `Средняя сумма за операцию`,
    
    -- 📉 ПОКВАРТАЛЬНЫЕ ПРОЦЕНТНЫЕ ДОЛИ
    -- Какую долю операций занимает группа внутри конкретного квартала от всех операций этого квартала
    ROUND((COUNT(*) / q.Total_Ops_Quarter) * 100, 2) AS `Доля от операций квартала (%)`,
    -- Какую долю выручки приносит группа внутри конкретного квартала от всей суммы этого квартала
    ROUND((SUM(r.Sum_payment) / q.Total_Sum_Quarter) * 100, 2) AS `Доля от суммы квартала (%)`

FROM RawData r
JOIN QuarterlyTotals q ON r.Quarter_Period = q.Quarter_Period
GROUP BY r.Age_Group, r.Quarter_Period, q.Total_Ops_Quarter, q.Total_Sum_Quarter
ORDER BY 
    -- Сортируем сначала по группам (чтобы 'Нет данных' или младшие шли последовательно), затем по хронологии кварталов
    FIELD(r.Age_Group, '0-9 лет', '10-19 лет', '20-29 лет', '30-39 лет', '40-49 лет', '50-59 лет', '60-69 лет', '70-79 лет', '80+ лет', 'Нет данных'), 
    r.Quarter_Period;
