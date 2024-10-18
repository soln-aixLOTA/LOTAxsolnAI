// web/assets/js/main.js

// Wait for the DOM to load
document.addEventListener('DOMContentLoaded', () => {
    // Load components
    loadComponent('header', './components/header.html').then(() => {
        setupNavbar();
    });
    loadComponent('footer', './components/footer.html');
    loadComponent('modal', './components/modal.html').then(() => {
        setupModal();
    });

    // Load initial view based on URL
    router();

    // Handle navigation
    window.onpopstate = router;

    // Delegate link clicks
    document.body.addEventListener('click', (e) => {
        if (e.target.matches('[data-link]') || e.target.closest('[data-link]')) {
            const link = e.target.closest('[data-link]');
            e.preventDefault();
            navigateTo(link.href);
        }
    });

    // Initialize theme toggle and hamburger menu
    setupThemeToggle();
    setupHamburgerMenu();
});

// Function to load HTML components
async function loadComponent(id, url) {
    const response = await fetch(url);
    if (!response.ok) {
        console.error(`Failed to load component ${id} from ${url}`);
        return;
    }
    const html = await response.text();
    document.getElementById(id).innerHTML = html;
}

// Function to navigate to a new URL
function navigateTo(url) {
    history.pushState(null, null, url);
    router();
}

// Router function to load the appropriate template
async function router() {
    const routes = {
        '/': './templates/home.html',
        '/dashboard': './templates/dashboard.html',
        '/chatbot': './templates/chatbot.html',
        '/analytics': './templates/analytics.html',
        '/about': './templates/about.html',
        '/contact': './templates/contact.html'
    };

    // Determine the path
    const path = window.location.pathname;

    // Get the template URL
    const template = routes[path] || './templates/404.html';

    // Fetch and display the template
    const app = document.getElementById('app');
    app.classList.add('loading');

    try {
        const response = await fetch(template);
        if (!response.ok) throw new Error(`Failed to load template: ${response.statusText}`);
        const html = await response.text();
        app.innerHTML = html;
    } catch (error) {
        console.error(error);
        app.innerHTML = '<p>Failed to load the page.</p>';
    }

    app.classList.remove('loading');

    // Initialize module-specific scripts
    if (path === '/chatbot') {
        initializeChatbot();
    } else if (path === '/analytics') {
        initializeAnalytics();
    } else if (path === '/contact') {
        initializeContactForm();
    }

    // Highlight active link
    highlightActiveLink();
}

// Function to load and initialize the Navbar
function setupNavbar() {
    const hamburger = document.getElementById('hamburger');
    const navLinks = document.getElementById('nav-links');

    hamburger.addEventListener('click', () => {
        navLinks.classList.toggle('active');
    });
}

// Function to highlight the active navigation link
function highlightActiveLink() {
    const path = window.location.pathname;
    const links = document.querySelectorAll('nav a[data-link]');

    links.forEach(link => {
        if (link.getAttribute('href') === path) {
            link.classList.add('active');
        } else {
            link.classList.remove('active');
        }
    });
}

// Function to set up the modal
function setupModal() {
    const modal = document.getElementById('modal');
    const closeModalBtn = document.getElementById('close-modal');

    closeModalBtn.addEventListener('click', () => {
        closeModal();
    });

    // Close modal when clicking outside content
    window.addEventListener('click', (e) => {
        if (e.target === modal) {
            closeModal();
        }
    });

    // Close modal on Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && modal.style.display === 'block') {
            closeModal();
        }
    });

    // Trap focus within the modal
    modal.addEventListener('keydown', (e) => {
        const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        if (e.key === 'Tab') {
            if (e.shiftKey) { // Shift + Tab
                if (document.activeElement === firstElement) {
                    e.preventDefault();
                    lastElement.focus();
                }
            } else { // Tab
                if (document.activeElement === lastElement) {
                    e.preventDefault();
                    firstElement.focus();
                }
            }
        }
    });
}

// Function to open the modal with specific content
function openModal(title, content) {
    const modal = document.getElementById('modal');
    const modalTitle = document.getElementById('modal-title');
    const modalBody = document.getElementById('modal-body');

    modalTitle.textContent = title;
    modalBody.innerHTML = content;
    modal.style.display = 'block';
}

// Function to close the modal
function closeModal() {
    const modal = document.getElementById('modal');
    modal.style.display = 'none';
}

// Function to set up the theme toggle
function setupThemeToggle() {
    const themeToggleBtn = document.getElementById('theme-toggle');
    const currentTheme = localStorage.getItem('theme') || 'light';

    if (currentTheme === 'dark') {
        document.body.classList.add('dark-mode');
    }

    themeToggleBtn.addEventListener('click', () => {
        document.body.classList.toggle('dark-mode');
        const theme = document.body.classList.contains('dark-mode') ? 'dark' : 'light';
        localStorage.setItem('theme', theme);
    });
}

// Function to initialize the Chatbot module
function initializeChatbot() {
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

// Function to initialize the Analytics module
async function initializeAnalytics() {
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

// Function to initialize the Contact form
function initializeContactForm() {
    const form = document.getElementById('contact-form');
    const responseDiv = document.getElementById('contact-response');

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const name = form.name.value.trim();
        const email = form.email.value.trim();
        const message = form.message.value.trim();
        let hasError = false;

        // Validate inputs
        if (!name) {
            showError('contact-name-error', 'Name is required.');
            hasError = true;
        } else {
            hideError('contact-name-error');
        }

        if (!email) {
            showError('contact-email-error', 'Email is required.');
            hasError = true;
        } else if (!validateEmail(email)) {
            showError('contact-email-error', 'Please enter a valid email.');
            hasError = true;
        } else {
            hideError('contact-email-error');
        }

        if (!message) {
            showError('contact-message-error', 'Message cannot be empty.');
            hasError = true;
        } else {
            hideError('contact-message-error');
        }

        if (hasError) return;

        // Show spinner
        showSpinner();

        // Clear previous response
        responseDiv.innerHTML = '';

        try {
            const res = await fetch('/api/contact', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ name, email, message })
            });

            if (!res.ok) throw new Error(`Error: ${res.status}`);

            const data = await res.json();
            responseDiv.innerHTML = `<p>${data.message}</p>`;
            showToast('Your message has been sent!', 'success');
            form.reset();
        } catch (error) {
            console.error(error);
            responseDiv.innerHTML = '<p>Failed to send your message. Please try again.</p>';
            showToast('Failed to send your message.', 'error');
        } finally {
            // Hide spinner
            hideSpinner();
        }
    });
}

// Helper Functions for Contact Form
function showError(elementId, message) {
    const errorElement = document.getElementById(elementId);
    errorElement.textContent = message;
    errorElement.style.display = 'block';
}

function hideError(elementId) {
    const errorElement = document.getElementById(elementId);
    errorElement.textContent = '';
    errorElement.style.display = 'none';
}

function validateEmail(email) {
    // Simple email regex
    const re = /\S+@\S+\.\S+/;
    return re.test(email);
}

// Function to show toast notifications
function showToast(message, type = 'success') {
    const toastContainer = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;

    toastContainer.appendChild(toast);

    // Trigger show animation
    setTimeout(() => {
        toast.classList.add('show');
    }, 100);

    // Hide after 3 seconds
    setTimeout(() => {
        toast.classList.remove('show');
        toast.classList.add('hide');
        toast.addEventListener('transitionend', () => {
            toast.remove();
        });
    }, 3000);
}

// Function to show the loading spinner
function showSpinner() {
    const spinner = document.getElementById('loading-spinner');
    if (spinner) spinner.hidden = false;
}

// Function to hide the loading spinner
function hideSpinner() {
    const spinner = document.getElementById('loading-spinner');
    if (spinner) spinner.hidden = true;
}

// Function to setup hamburger menu
function setupHamburgerMenu() {
    const hamburger = document.getElementById('hamburger');
    const navLinks = document.getElementById('nav-links');

    hamburger.addEventListener('click', () => {
        navLinks.classList.toggle('active');
    });
}
