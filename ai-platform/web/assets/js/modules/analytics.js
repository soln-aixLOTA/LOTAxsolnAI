// web/assets/js/modules/analytics.js

export function initializeAnalyticsModule() {
    const ctx = document.getElementById('analyticsChart').getContext('2d');

    try {
        const res = await fetch('/api/analytics/data');
        if (!res.ok) throw new Error(`Error: ${res.status}`);
        const data = await res.json();

        const analyticsChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.labels,
                datasets: [{
                    label: 'Risk Scores',
                    data: data.values,
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    borderColor: 'rgba(75, 192, 192, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
    } catch (error) {
        console.error(error);
        ctx.parentElement.innerHTML = '<p>Failed to load analytics data.</p>';
        showToast('Failed to load analytics data.', 'error');
    }
}
