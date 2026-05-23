#!/bin/bash

#===============================================================================
# Szablon projektu: Prosta aplikacja webowa (HTML/CSS/JS)
# Template: Simple Web Application
#===============================================================================

set -euo pipefail

PROJECT_NAME="${1:-my-web-app}"
PROJECT_DIR="${2:-./${PROJECT_NAME}}"

echo "🌐 Tworzenie projektu webowego: $PROJECT_NAME"
echo "Lokalizacja: $PROJECT_DIR"

# Tworzenie struktury katalogów
mkdir -p "$PROJECT_DIR"/{css,js,images,templates}

# index.html
cat > "$PROJECT_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Web App</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header>
        <h1>Welcome to My Web App</h1>
        <nav>
            <ul>
                <li><a href="#home">Home</a></li>
                <li><a href="#about">About</a></li>
                <li><a href="#contact">Contact</a></li>
            </ul>
        </nav>
    </header>

    <main>
        <section id="home">
            <h2>Home Section</h2>
            <p>This is the main content area.</p>
        </section>

        <section id="about">
            <h2>About Us</h2>
            <p>Learn more about our project.</p>
        </section>

        <section id="contact">
            <h2>Contact</h2>
            <form id="contact-form">
                <input type="text" id="name" placeholder="Your Name" required>
                <input type="email" id="email" placeholder="Your Email" required>
                <textarea id="message" placeholder="Your Message" required></textarea>
                <button type="submit">Send</button>
            </form>
        </section>
    </main>

    <footer>
        <p>&copy; 2024 My Web App. All rights reserved.</p>
    </footer>

    <script src="js/app.js"></script>
</body>
</html>
EOF

# css/style.css
cat > "$PROJECT_DIR/css/style.css" << 'EOF'
/* Reset and Base Styles */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
    background-color: #f4f4f4;
}

/* Header */
header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1rem 0;
    text-align: center;
}

header h1 {
    margin-bottom: 1rem;
}

nav ul {
    list-style: none;
    display: flex;
    justify-content: center;
    gap: 2rem;
}

nav a {
    color: white;
    text-decoration: none;
    font-weight: bold;
    transition: opacity 0.3s;
}

nav a:hover {
    opacity: 0.8;
}

/* Main Content */
main {
    max-width: 1200px;
    margin: 2rem auto;
    padding: 0 1rem;
}

section {
    background: white;
    padding: 2rem;
    margin-bottom: 2rem;
    border-radius: 8px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

section h2 {
    color: #667eea;
    margin-bottom: 1rem;
}

/* Form Styles */
form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

input, textarea {
    padding: 0.8rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 1rem;
}

textarea {
    min-height: 150px;
    resize: vertical;
}

button {
    background: #667eea;
    color: white;
    padding: 0.8rem;
    border: none;
    border-radius: 4px;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.3s;
}

button:hover {
    background: #764ba2;
}

/* Footer */
footer {
    text-align: center;
    padding: 2rem;
    background: #333;
    color: white;
    margin-top: 2rem;
}

/* Responsive */
@media (max-width: 768px) {
    nav ul {
        flex-direction: column;
        gap: 1rem;
    }
}
EOF

# js/app.js
cat > "$PROJECT_DIR/js/app.js" << 'EOF'
// Main Application JavaScript
document.addEventListener('DOMContentLoaded', function() {
    console.log('Web App Initialized');

    // Contact Form Handler
    const contactForm = document.getElementById('contact-form');
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const name = document.getElementById('name').value;
            const email = document.getElementById('email').value;
            const message = document.getElementById('message').value;

            console.log('Form submitted:', { name, email, message });
            
            // Show success message
            alert(`Thank you, ${name}! Your message has been sent.`);
            
            // Reset form
            contactForm.reset();
        });
    }

    // Smooth scrolling for navigation links
    document.querySelectorAll('nav a').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                e.preventDefault();
                targetSection.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
    });

    // Add fade-in animation to sections
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.1 });

    document.querySelectorAll('section').forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(20px)';
        section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(section);
    });
});
EOF

# README.md
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

Simple web application template with HTML, CSS, and JavaScript.

## Structure

\`\`\`
$PROJECT_NAME/
├── index.html          # Main HTML file
├── css/
│   └── style.css       # Stylesheet
├── js/
│   └── app.js          # JavaScript code
├── images/             # Image assets
└── templates/          # HTML templates
\`\`\`

## Features

- Responsive design
- Modern CSS with gradients and animations
- Form handling with validation
- Smooth scrolling navigation
- Intersection Observer for animations

## Usage

Simply open \`index.html\` in a web browser.

## License

MIT License
EOF

# .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
.DS_Store
*.log
.env
node_modules/
dist/
build/
EOF

echo ""
echo "✅ Projekt webowy utworzony pomyślnie!"
echo ""
echo "Struktura projektu:"
find "$PROJECT_DIR" -type f | sort | sed "s|$PROJECT_DIR||"
echo ""
echo "Aby uruchomić, otwórz plik index.html w przeglądarce lub użyj:"
echo "  python3 -m http.server 8000 --directory $PROJECT_DIR"
