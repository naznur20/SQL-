-- a)средняя сумма чека в месяц;
-- b)среднее количество операций в месяц;
-- c)среднее количество клиентов, которые совершали операции;
-- d)долю от общего количества операций за год и долю в месяц от общей суммы операций;
-- e)вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

WITH YearlyTotals AS (
    -- Шаг 1: Считаем глобальные итоги за весь год для расчета долей
    SELECT 
        COUNT(*) AS Total_Ops_Year,
        SUM(Sum_payment) AS Total_Sum_Year,
        -- Считаем количество месяцев в периоде (используется для расчета средних в месяц)
        COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS Total_Months_Count
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
MonthlyAggregates AS (
    -- Шаг 2: Группируем данные помесячно и агрегируем по гендерным признакам
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS Month_Period,
        COUNT(DISTINCT t.Id_check) AS Monthly_Checks_Count,
        COUNT(*) AS Monthly_Ops_Count,
        SUM(t.Sum_payment) AS Monthly_Sum_Payment,
        COUNT(DISTINCT t.ID_client) AS Monthly_Clients_Count,
        
        -- Количество операций по полам в конкретном месяце
        COUNT(CASE WHEN IFNULL(c.Gender, '') in ('', 'NA') THEN 1 END) AS Ops_NA,
        COUNT(CASE WHEN c.Gender = 'M' THEN 1 END) AS Ops_M,
        COUNT(CASE WHEN c.Gender = 'F' THEN 1 END) AS Ops_F,
        
        -- Суммы затрат по полам в конкретном месяце
        SUM(CASE WHEN IFNULL(c.Gender, '') in ('', 'NA') THEN t.Sum_payment ELSE 0 END) AS Sum_NA,
        SUM(CASE WHEN c.Gender = 'M' THEN t.Sum_payment ELSE 0 END) AS Sum_M,
        SUM(CASE WHEN c.Gender = 'F' THEN t.Sum_payment ELSE 0 END) AS Sum_F
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
)
-- Шаг 3: Формируем финальный отчет
SELECT 
    a.Month_Period AS `Месяц`,
    
    -- a) Средняя сумма чека в месяц (усредненная за весь период через оконную функцию)
    ROUND(AVG(a.Monthly_Sum_Payment / a.Monthly_Checks_Count) OVER(), 2) AS `a) Средний чек в месяц (за период)`,
    
    -- b) Среднее количество операций в месяц (всего операций за год / количество месяцев)
    ROUND(y.Total_Ops_Year / y.Total_Months_Count, 1) AS `b) Среднее кол-во операций в месяц`,
    
    -- c) Среднее количество клиентов, совершавших операции в месяц
    ROUND(AVG(a.Monthly_Clients_Count) OVER(), 1) AS `c) Среднее кол-во клиентов в месяц`,
    
    -- d) Доля от общего количества операций за год и доля в месяц от общей суммы операций за год
    ROUND((a.Monthly_Ops_Count / y.Total_Ops_Year) * 100, 2) AS `d) Доля операций от года (%)`,
    ROUND((a.Monthly_Sum_Payment / y.Total_Sum_Year) * 100, 2) AS `d) Доля затрат от года (%)`,
    
    -- e) % соотношение M/F/NA по количеству операций в каждом месяце
    ROUND((a.Ops_M / a.Monthly_Ops_Count) * 100, 2) AS `e) % Операций Мужчины (M)`,
    ROUND((a.Ops_F / a.Monthly_Ops_Count) * 100, 2) AS `e) % Операций Женщины (F)`,
    ROUND((a.Ops_NA / a.Monthly_Ops_Count) * 100, 2) AS `e) % Операций Нет данных (NA)`,
    
    -- e) Доля затрат M/F/NA от общей суммы затрат за конкретный месяц
    ROUND((a.Sum_M / a.Monthly_Sum_Payment) * 100, 2) AS `e) Доля затрат M (%)`,
    ROUND((a.Sum_F / a.Monthly_Sum_Payment) * 100, 2) AS `e) Доля затрат F (%)`,
    ROUND((a.Sum_NA / a.Monthly_Sum_Payment) * 100, 2) AS `e) Доля затрат NA (%)`

FROM MonthlyAggregates a
CROSS JOIN YearlyTotals y
ORDER BY a.Month_Period;

