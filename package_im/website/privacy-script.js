// 平滑滚动
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const offsetTop = target.offsetTop - 100; // 减去导航栏高度和一些额外空间
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    });
});

// 导航栏滚动效果
window.addEventListener('scroll', function() {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.boxShadow = '0 2px 30px rgba(0, 0, 0, 0.1)';
    } else {
        navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.05)';
    }
});

// 高亮当前阅读的章节（目录跟随）
const sections = document.querySelectorAll('.policy-section[id]');
const tocLinks = document.querySelectorAll('.toc a');

function highlightTOC() {
    let currentSection = '';
    
    sections.forEach(section => {
        const sectionTop = section.offsetTop - 150;
        const sectionHeight = section.offsetHeight;
        
        if (window.scrollY >= sectionTop && window.scrollY < sectionTop + sectionHeight) {
            currentSection = section.getAttribute('id');
        }
    });
    
    tocLinks.forEach(link => {
        link.style.background = '';
        link.style.color = '';
        link.style.fontWeight = '';
        
        if (link.getAttribute('href') === `#${currentSection}`) {
            link.style.background = 'linear-gradient(135deg, #AB47BC, #7B1FA2)';
            link.style.color = '#FFFFFF';
            link.style.fontWeight = '600';
        }
    });
}

// 监听滚动事件
window.addEventListener('scroll', highlightTOC);

// 页面加载完成后执行
document.addEventListener('DOMContentLoaded', function() {
    highlightTOC();
    
    // 添加淡入动画
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });
    
    // 观察所有政策章节
    document.querySelectorAll('.policy-section').forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(30px)';
        section.style.transition = 'all 0.6s ease-out';
        observer.observe(section);
    });
});

// 添加返回顶部按钮
function createBackToTop() {
    const button = document.createElement('button');
    button.innerHTML = '↑';
    button.className = 'back-to-top';
    button.style.cssText = `
        position: fixed;
        bottom: 40px;
        right: 40px;
        width: 50px;
        height: 50px;
        border-radius: 50%;
        background: linear-gradient(135deg, #AB47BC, #7B1FA2);
        color: white;
        border: none;
        font-size: 24px;
        cursor: pointer;
        opacity: 0;
        visibility: hidden;
        transition: all 0.3s;
        box-shadow: 0 4px 15px rgba(171, 71, 188, 0.3);
        z-index: 999;
    `;
    
    document.body.appendChild(button);
    
    // 显示/隐藏按钮
    window.addEventListener('scroll', function() {
        if (window.scrollY > 500) {
            button.style.opacity = '1';
            button.style.visibility = 'visible';
        } else {
            button.style.opacity = '0';
            button.style.visibility = 'hidden';
        }
    });
    
    // 点击返回顶部
    button.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
    
    // 悬停效果
    button.addEventListener('mouseenter', function() {
        this.style.transform = 'scale(1.1) translateY(-5px)';
        this.style.boxShadow = '0 6px 20px rgba(171, 71, 188, 0.4)';
    });
    
    button.addEventListener('mouseleave', function() {
        this.style.transform = 'scale(1) translateY(0)';
        this.style.boxShadow = '0 4px 15px rgba(171, 71, 188, 0.3)';
    });
}

createBackToTop();

// 打印功能
function addPrintButton() {
    const printButton = document.createElement('button');
    printButton.innerHTML = '🖨️ 打印';
    printButton.style.cssText = `
        position: fixed;
        bottom: 100px;
        right: 40px;
        padding: 12px 24px;
        border-radius: 25px;
        background: white;
        color: #AB47BC;
        border: 2px solid #AB47BC;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        opacity: 0;
        visibility: hidden;
        transition: all 0.3s;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        z-index: 999;
    `;
    
    document.body.appendChild(printButton);
    
    // 显示/隐藏按钮
    window.addEventListener('scroll', function() {
        if (window.scrollY > 500) {
            printButton.style.opacity = '1';
            printButton.style.visibility = 'visible';
        } else {
            printButton.style.opacity = '0';
            printButton.style.visibility = 'hidden';
        }
    });
    
    // 点击打印
    printButton.addEventListener('click', function() {
        window.print();
    });
    
    // 悬停效果
    printButton.addEventListener('mouseenter', function() {
        this.style.background = '#AB47BC';
        this.style.color = 'white';
        this.style.transform = 'translateY(-3px)';
        this.style.boxShadow = '0 6px 20px rgba(171, 71, 188, 0.3)';
    });
    
    printButton.addEventListener('mouseleave', function() {
        this.style.background = 'white';
        this.style.color = '#AB47BC';
        this.style.transform = 'translateY(0)';
        this.style.boxShadow = '0 4px 15px rgba(0, 0, 0, 0.1)';
    });
}

addPrintButton();

// 移动端菜单
function createMobileMenu() {
    if (window.innerWidth <= 768) {
        const navbar = document.querySelector('.navbar .container');
        const navMenu = document.querySelector('.nav-menu');
        
        // 创建汉堡菜单按钮
        const menuToggle = document.createElement('button');
        menuToggle.className = 'menu-toggle';
        menuToggle.innerHTML = '☰';
        menuToggle.style.cssText = `
            background: none;
            border: none;
            font-size: 28px;
            color: #AB47BC;
            cursor: pointer;
        `;
        
        navbar.appendChild(menuToggle);
        
        // 初始隐藏菜单
        navMenu.style.display = 'none';
        
        menuToggle.addEventListener('click', function() {
            if (navMenu.style.display === 'none') {
                navMenu.style.display = 'flex';
                navMenu.style.flexDirection = 'column';
                navMenu.style.position = 'absolute';
                navMenu.style.top = '60px';
                navMenu.style.right = '20px';
                navMenu.style.background = 'white';
                navMenu.style.padding = '20px';
                navMenu.style.borderRadius = '10px';
                navMenu.style.boxShadow = '0 5px 20px rgba(0,0,0,0.1)';
                menuToggle.innerHTML = '✕';
            } else {
                navMenu.style.display = 'none';
                menuToggle.innerHTML = '☰';
            }
        });
    }
}

document.addEventListener('DOMContentLoaded', createMobileMenu);

// 复制链接功能（点击章节标题复制链接）
document.querySelectorAll('.policy-section h2').forEach(heading => {
    heading.style.cursor = 'pointer';
    heading.title = '点击复制链接';
    
    heading.addEventListener('click', function() {
        const section = this.parentElement;
        const sectionId = section.getAttribute('id');
        if (sectionId) {
            const url = window.location.origin + window.location.pathname + '#' + sectionId;
            
            // 创建临时输入框复制链接
            const tempInput = document.createElement('input');
            tempInput.value = url;
            document.body.appendChild(tempInput);
            tempInput.select();
            document.execCommand('copy');
            document.body.removeChild(tempInput);
            
            // 显示提示
            const toast = document.createElement('div');
            toast.innerHTML = '✓ 链接已复制';
            toast.style.cssText = `
                position: fixed;
                top: 100px;
                right: 20px;
                background: linear-gradient(135deg, #AB47BC, #7B1FA2);
                color: white;
                padding: 15px 25px;
                border-radius: 8px;
                box-shadow: 0 4px 15px rgba(171, 71, 188, 0.3);
                z-index: 9999;
                animation: slideIn 0.3s ease-out;
            `;
            
            document.body.appendChild(toast);
            
            setTimeout(() => {
                toast.style.animation = 'slideOut 0.3s ease-out';
                setTimeout(() => {
                    document.body.removeChild(toast);
                }, 300);
            }, 2000);
        }
    });
});

// 添加动画样式
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

