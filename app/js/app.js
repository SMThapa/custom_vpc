const category = document.querySelectorAll(".opt")
category.forEach(item =>{
    item.addEventListener('click', ()=>{
        category.forEach(i=> i.classList.remove("active"))
        item.classList.add('active')
    })
})

const accordian = document.querySelectorAll('.accordian')
accordian.forEach(item => {    
    item.addEventListener('click', ()=>{
        accordian.forEach(i => i.classList.remove('active'));
        item.classList.toggle('active')
    })
})