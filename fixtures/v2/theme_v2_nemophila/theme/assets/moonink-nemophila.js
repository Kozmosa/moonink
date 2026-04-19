const toggle = document.querySelector('.nemophila-menu-toggle')
const nav = document.querySelector('.nemophila-nav')

if (toggle && nav) {
  toggle.addEventListener('click', () => {
    const expanded = toggle.getAttribute('aria-expanded') === 'true'
    toggle.setAttribute('aria-expanded', expanded ? 'false' : 'true')
    nav.dataset.open = expanded ? 'false' : 'true'
  })
}
