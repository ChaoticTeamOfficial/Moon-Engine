// copy button functionality
document.querySelectorAll('.copy-btn').forEach(button => {
    button.addEventListener('click', () => {
        const codeElement = button.previousElementSibling.querySelector('code');
        const textToCopy = codeElement.textContent;
		
		// this button looks so cuteyyy,, >w<
        navigator.clipboard.writeText(textToCopy).then(() => {
            button.textContent = '✓ Copied';
            setTimeout(() => {
                button.textContent = 'Copy';
            }, 1600);
        });
    });
});

const sections = document.querySelectorAll('section');
const navLinks = document.querySelectorAll('.sidebar-menu a');
const indicator = document.querySelector('.sidebar-indicator');

function updateActiveSection() {
    let currentSectionId = sections[0].id;

    sections.forEach(section => {
        const rect = section.getBoundingClientRect();
        if (rect.top <= 120) {
            currentSectionId = section.id;
        }
    });

    navLinks.forEach(link => {
        const isActive = link.getAttribute('href') === `#${currentSectionId}`;
        link.classList.toggle('active', isActive);

        if (isActive) {
            const linkRect = link.getBoundingClientRect();
            const menuRect = link.closest('.sidebar-menu').getBoundingClientRect();

            indicator.style.top = `${linkRect.top - menuRect.top}px`;
            indicator.style.height = `${linkRect.height}px`;
            indicator.style.opacity = '1';
        }
    });
}

window.addEventListener('scroll', updateActiveSection);
window.addEventListener('load', updateActiveSection);