-- 1. List all Business Units

SELECT * FROM business_units;

-- 2. Show all processes with their associated Business Unit

SELECT p.process_name, b.bu_name
FROM processes p
JOIN business_units b ON p.bu_id = b.bu_id;

-- 3. Count of risks in the system

SELECT COUNT(*) AS total_risks FROM risks;

-- 4. List all controls and their owners

SELECT control_name, owner FROM controls;

-- 5. Find all risks mapped to 'Dual Verification' control

SELECT r.risk_description
FROM risks r
JOIN control_risk_map crm ON r.risk_id = crm.risk_id
JOIN controls c ON crm.control_id = c.control_id
WHERE c.control_name = 'Dual Verification';

-- 6. Show average inherent and residual risk score by BU

SELECT b.bu_name, AVG(ps.inherent_risk_score) AS avg_inherent, AVG(ps.residual_risk_score) AS avg_residual
FROM prsa_scores ps
JOIN processes p ON ps.process_id = p.process_id
JOIN business_units b ON p.bu_id = b.bu_id
GROUP BY b.bu_name;

-- 7. List all failed control tests

SELECT * FROM control_tests WHERE test_result = 'Fail';

-- 8. Controls with more than one failure

SELECT c.control_name, COUNT(*) AS fail_count
FROM control_tests ct
JOIN controls c ON ct.control_id = c.control_id
WHERE ct.test_result = 'Fail'
GROUP BY c.control_name
HAVING COUNT(*) > 1;

-- 9. Risk count by severity level

SELECT severity, COUNT(*) AS risk_count FROM risks GROUP BY severity ORDER BY severity DESC;

-- 10. List processes with high residual risk (>6)

SELECT p.process_name, ps.residual_risk_score
FROM prsa_scores ps
JOIN processes p ON ps.process_id = p.process_id
WHERE ps.residual_risk_score > 6;

-- 11. Top 3 BUs with the highest average residual risk

SELECT b.bu_name, AVG(ps.residual_risk_score) AS avg_residual
FROM prsa_scores ps
JOIN processes p ON ps.process_id = p.process_id
JOIN business_units b ON p.bu_id = b.bu_id
GROUP BY b.bu_name
ORDER BY avg_residual DESC
LIMIT 3;

-- 12. Identify controls mapped to the most severe risks

SELECT DISTINCT c.control_name, r.severity
FROM control_risk_map crm
JOIN risks r ON crm.risk_id = r.risk_id
JOIN controls c ON crm.control_id = c.control_id
WHERE r.severity = (SELECT MAX(severity) FROM risks);

-- 13. Failure rate per control (fail/total tests)

SELECT c.control_name,
       COUNT(CASE WHEN ct.test_result = 'Fail' THEN 1 END) * 100.0 / COUNT(*) AS failure_rate_pct
FROM control_tests ct
JOIN controls c ON ct.control_id = c.control_id
GROUP BY c.control_name;

-- 14. Controls that have only ever passed QA tests

SELECT c.control_name
FROM controls c
WHERE NOT EXISTS (
    SELECT 1 FROM control_tests ct
    WHERE ct.control_id = c.control_id AND ct.test_result = 'Fail'
);

-- 15. Average control effectiveness score by BU (simulated by mapping effectiveness levels)

SELECT b.bu_name,
       AVG(CASE ps.control_effectiveness
           WHEN 'Strong' THEN 5
           WHEN 'Effective' THEN 4
           WHEN 'Moderate' THEN 3
           WHEN 'Weak' THEN 2
           ELSE 1 END) AS avg_effectiveness_score
FROM prsa_scores ps
JOIN processes p ON ps.process_id = p.process_id
JOIN business_units b ON p.bu_id = b.bu_id
GROUP BY b.bu_name;

-- 16. Root cause analysis: Which risks lead to the most failed controls?

SELECT r.risk_description, COUNT(*) AS fail_count
FROM control_tests ct
JOIN controls c ON ct.control_id = c.control_id
JOIN control_risk_map crm ON c.control_id = crm.control_id
JOIN risks r ON crm.risk_id = r.risk_id
WHERE ct.test_result = 'Fail'
GROUP BY r.risk_description
ORDER BY fail_count DESC;

-- 17. Control frequency distribution

SELECT frequency, COUNT(*) AS control_count FROM controls GROUP BY frequency;

-- 18. List processes with both high inherent risk (>8) and low control effectiveness ('Weak')

SELECT p.process_name, ps.inherent_risk_score, ps.control_effectiveness
FROM prsa_scores ps
JOIN processes p ON ps.process_id = p.process_id
WHERE ps.inherent_risk_score > 8 AND ps.control_effectiveness = 'Weak';

-- 19. Count of QA tests by control and result

SELECT c.control_name, ct.test_result, COUNT(*) AS test_count
FROM control_tests ct
JOIN controls c ON ct.control_id = c.control_id
GROUP BY c.control_name, ct.test_result
ORDER BY c.control_name;

-- 20. Controls tied to multiple risks (complex mapping)

SELECT c.control_name, COUNT(DISTINCT crm.risk_id) AS risk_link_count
FROM controls c
JOIN control_risk_map crm ON c.control_id = crm.control_id
GROUP BY c.control_name
HAVING COUNT(DISTINCT crm.risk_id) > 1;

