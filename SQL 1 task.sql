-- Cписок клиентов с непрерывной историей за год, 
-- то есть каждый месяц на регулярной основе без пропусков за указанный годовой период, 
-- средний чек за период с 01.06.2015 по 01.06.2016, 
-- средняя сумма покупок за месяц, количество всех операций по клиенту за период;
-- информацию в разрезе месяцев:

-- Шаг 1: Находим клиентов, у которых есть покупки в каждом из 13 месяцев периода
WITH ActiveCustomers AS (
    SELECT ID_client
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client
    HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 13
),
MonthlyAggregates AS (
    -- Шаг 2: Считаем сумму, количество чеков и операций для каждого клиента помесячно
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS `Month`,
        t.ID_client,
        SUM(t.Sum_payment) AS Monthly_Sum_Payment,
        COUNT(DISTINCT t.Id_check) AS Monthly_Checks_Count,
        COUNT(*) AS Monthly_Operations_Count
    FROM transactions t
    JOIN ActiveCustomers ac ON t.ID_client = ac.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m'), t.ID_client
)
-- Шаг 3: Собираем финальную таблицу со всеми глобальными и помесячными метриками
SELECT 
    m.ID_client,
    m.`Month` AS `Месяц`,
    
    -- Метрики в разрезе конкретного месяца
    ROUND(m.Monthly_Sum_Payment, 2) AS `Сумма покупок за месяц`,
    ROUND(m.Monthly_Sum_Payment / m.Monthly_Checks_Count, 2) AS `Средний чек за месяц`,
    m.Monthly_Operations_Count AS `Количество операций за месяц`,
    
    -- Глобальные метрики за весь годовой период (посчитаны через оконные функции)
    ROUND(SUM(m.Monthly_Sum_Payment) OVER(PARTITION BY m.ID_client) / 
          SUM(m.Monthly_Checks_Count) OVER(PARTITION BY m.ID_client), 2) AS `Средний чек за весь период`,
          
    ROUND(SUM(m.Monthly_Sum_Payment) OVER(PARTITION BY m.ID_client) / 13, 2) AS `Средняя сумма покупок за месяц (за период)`,
    
    SUM(m.Monthly_Operations_Count) OVER(PARTITION BY m.ID_client) AS `Количество всех операций за период`

FROM MonthlyAggregates m
ORDER BY m.ID_client, m.`Month`;
