// 截图轮播功能
let currentSlideIndex = 0;
const slides = document.querySelectorAll('.slide');
const dots = document.querySelectorAll('.dot');

// 显示指定的幻灯片
function showSlide(index) {
    // 确保索引在有效范围内
    if (index >= slides.length) {
        currentSlideIndex = 0;
    } else if (index < 0) {
        currentSlideIndex = slides.length - 1;
    } else {
        currentSlideIndex = index;
    }
    
    // 隐藏所有幻灯片
    slides.forEach(slide => {
        slide.classList.remove('active');
    });
    
    // 移除所有圆点的激活状态
    dots.forEach(dot => {
        dot.classList.remove('active');
    });
    
    // 显示当前幻灯片
    slides[currentSlideIndex].classList.add('active');
    dots[currentSlideIndex].classList.add('active');
}

// 切换幻灯片
function changeSlide(direction) {
    showSlide(currentSlideIndex + direction);
}

// 直接跳转到指定幻灯片
function currentSlide(index) {
    showSlide(index);
}

// 自动播放
function autoPlay() {
    changeSlide(1);
}

// 每5秒自动切换
let autoPlayInterval = setInterval(autoPlay, 5000);

// 当用户手动操作时，重置自动播放计时器
function resetAutoPlay() {
    clearInterval(autoPlayInterval);
    autoPlayInterval = setInterval(autoPlay, 5000);
}

// 为按钮添加重置自动播放功能
document.querySelectorAll('.slider-btn').forEach(btn => {
    btn.addEventListener('click', resetAutoPlay);
});

document.querySelectorAll('.dot').forEach(dot => {
    dot.addEventListener('click', resetAutoPlay);
});

// 平滑滚动
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const offsetTop = target.offsetTop - 80; // 减去导航栏高度
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
    if (window.scrollY > 100) {
        navbar.style.boxShadow = '0 2px 30px rgba(0, 0, 0, 0.1)';
    } else {
        navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.05)';
    }
});

// 添加滚动动画
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// 观察所有功能卡片
document.querySelectorAll('.feature-card').forEach(card => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(30px)';
    card.style.transition = 'all 0.6s ease-out';
    observer.observe(card);
});

// 观察下载卡片
document.querySelectorAll('.download-card').forEach(card => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(30px)';
    card.style.transition = 'all 0.6s ease-out';
    observer.observe(card);
});

// 观察功能展示卡片
document.querySelectorAll('.showcase-item').forEach((item, index) => {
    item.style.opacity = '0';
    item.style.transform = 'translateY(50px)';
    item.style.transition = `all 0.8s ease-out ${index * 0.1}s`;
    observer.observe(item);
});

// 观察技术卡片
document.querySelectorAll('.tech-card').forEach((card, index) => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(30px)';
    card.style.transition = `all 0.6s ease-out ${index * 0.1}s`;
    observer.observe(card);
});

// 移动端菜单切换（如果需要）
function createMobileMenu() {
    const navbar = document.querySelector('.navbar .container');
    const navMenu = document.querySelector('.nav-menu');
    
    // 创建汉堡菜单按钮
    const menuToggle = document.createElement('button');
    menuToggle.className = 'menu-toggle';
    menuToggle.innerHTML = '☰';
    menuToggle.style.cssText = `
        display: none;
        background: none;
        border: none;
        font-size: 28px;
        color: var(--primary-color);
        cursor: pointer;
    `;
    
    // 在移动端显示
    if (window.innerWidth <= 768) {
        menuToggle.style.display = 'block';
        navbar.appendChild(menuToggle);
        
        menuToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            if (navMenu.classList.contains('active')) {
                navMenu.style.display = 'flex';
                navMenu.style.flexDirection = 'column';
                navMenu.style.position = 'absolute';
                navMenu.style.top = '60px';
                navMenu.style.right = '20px';
                navMenu.style.background = 'white';
                navMenu.style.padding = '20px';
                navMenu.style.borderRadius = '10px';
                navMenu.style.boxShadow = '0 5px 20px rgba(0,0,0,0.1)';
            } else {
                navMenu.style.display = 'none';
            }
        });
    }
}

// 页面加载完成后执行
document.addEventListener('DOMContentLoaded', function() {
    createMobileMenu();
});

// 窗口大小改变时重新检查
window.addEventListener('resize', function() {
    const navMenu = document.querySelector('.nav-menu');
    if (window.innerWidth > 768) {
        navMenu.style.display = 'flex';
        navMenu.style.position = 'static';
        navMenu.style.flexDirection = 'row';
    } else {
        navMenu.style.display = 'none';
    }
});

