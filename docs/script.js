// copy button functionality
document.querySelectorAll('.copy-btn').forEach(button => {
    button.addEventListener('click', () => {
        const codeElement = button.previousElementSibling.querySelector('code');
        const textToCopy = codeElement.textContent;
        navigator.clipboard.writeText(textToCopy).then(() => {
            button.textContent = '✓ Copied';
            setTimeout(() => {
                button.textContent = 'Copy';
            }, 1600);
        });
    });
});

// scrolling and active section
const sections = document.querySelectorAll('section, .json-fields');
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

// collapsible submenus
document.querySelectorAll('.has-submenu').forEach(item => {
    const arrow = item.querySelector('.toggle-arrow');
    const submenu = item.querySelector('.submenu');
    const parentA = item.querySelector('a');

    if (arrow && submenu) {
        arrow.addEventListener('click', e => {
            e.preventDefault();
            e.stopPropagation();
            const willOpen = !item.classList.contains('open');
            item.classList.toggle('open');
            submenu.style.display = willOpen ? 'block' : 'none';
        });

        parentA.addEventListener('click', () => {
            if (!item.classList.contains('open')) {
                item.classList.add('open');
                submenu.style.display = 'block';
            }
        });
    }
});

window.addEventListener('scroll', updateActiveSection);
window.addEventListener('load', updateActiveSection);