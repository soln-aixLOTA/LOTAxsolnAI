// web/assets/js/modules/chatbot.js

export function initializeChatbotModule() {
    const form = document.getElementById('chatbot-form');
    const responseDiv = document.getElementById('chatbot-response');

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const prompt = form.prompt.value.trim();

        if (!prompt) {
            showToast('Please enter a message.', 'error');
            return;
        }

        // Show spinner
        showSpinner();

        // Clear previous response
        responseDiv.innerHTML = '';

        try {
            const res = await fetch('/api/chatbot', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ prompt })
            });

            if (!res.ok) throw new Error(`Error: ${res.status}`);

            const data = await res.json();
            responseDiv.innerHTML = `<p><strong>Chatbot:</strong> ${data.message}</p>`;
            showToast('Chatbot response received!', 'success');
        } catch (error) {
            console.error(error);
            responseDiv.innerHTML = '<p>Failed to get response. Please try again.</p>';
            showToast('Failed to get response.', 'error');
        } finally {
            // Hide spinner
            hideSpinner();
        }
    });
}
