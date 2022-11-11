require "HTTParty"
require 'net/http'

# require "google/apis/compute_v1"
# require "google/cloud/storage"

# ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class HomeController < ApplicationController
  
  def show
  end
  
  def test_response
    
    # bucket_name_with_site = "maysen.maysengreenwood.com"
    
    # storage = Google::Cloud::Storage.new
    # bucket  = storage.bucket bucket_name_with_site
    
    # file_name_plus_type = "all_website.html"
    
    # file = bucket.file file_name_plus_type
    
    # downloaded = file.download
      
    # # Workaround from downloaded.read due to UTF-8 encoding issues
    # #contents = downloaded.read.force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: '')
    
    # render html: downloaded.read.html_safe
    
      
    # Testing responding with rendered html
    
#     my_var = "Hello!"
#     my_var_2 = "A second hello!"
    
#     content_for_layout = %{
#       <div class="container">
#     <a class="navbar-brand d-flex align-items-center" href="/">
#       <span>Maysen Greenwood</span>
#     </a>
#     <button class="navbar-toggler" data-bs-toggle="collapse" data-bs-target="#navcol-5"><span class="visually-hidden">Toggle navigation</span><span class="navbar-toggler-icon"></span></button>
#     <div id="navcol-5" class="mt-3 collapse navbar-collapse">
#       <ul class="navbar-nav ms-auto justify-content-evenly flex-row">
#         <li class="nav-item"><a class="nav-link show-on-scroll" href="#about" onclick="updateActiveNavLink('about');">About me</a></li>
#         <li class="nav-item"><a class="nav-link show-on-scroll" href="#projects" onclick="updateActiveNavLink('projects');">My projects</a></li>
#         <li class="nav-item"><a class="nav-link show-on-scroll" href="#contact-me" onclick="updateActiveNavLink('contact-me');">Contact me</a></li>
#         <li class="nav-item"><a target="_blank" rel="noreferrer noopener" class="nav-link" href="https://github.com/MaysenTG"><i class="bi-github"></i></a></li>
#         <li class="nav-item"><a target="_blank" rel="noreferrer noopener" class="nav-link" href="https://www.linkedin.com/in/maysen-greenwood/"><i class="bi-linkedin"></i></a></li>
#       </ul>
#     </div>
#   </div>
# </nav>
#     </header>
#     <main>
#       <section class="blank" style="margin-top: 5%; margin-bottom: 10%; height: 100%;">
#   <div class="container">
#     <div class="border rounded border-0 d-flex flex-column align-items-center" style="width: 100%; margin-top: 5rem; margin-bottom: 5rem;">
#       <div style="width: 100%;" class="col-12 text-center d-flex d-sm-flex d-md-flex align-items-center mx-auto align-items-md-center">
#         <div class="hero-section-contents" style="width: 100vw; margin-top: 3rem;">
#           <p class="mb-4">Hey! <br> I'm Maysen and I'm a <br></p>
#           <h1 class="text-uppercase fw-bold mb-3"><strong>Front end <br> developer</strong></h1>
#           <p class="mb-4 hero-subtext">but also a Kiwi, Rubiks cube master, Dog Dad, Skiier and Star Gazer... </p>
#           <button class="btn btn-light fs-5 py-2 px-4 coolMainButton" onclick="document.getElementById('projects').scrollIntoView();" type="button">Check out some of my projects</button>
#         </div>
#       </div>
#     </div>
#   </div>
# </section>
# <!-- About me section -->
# <section class="py-4 py-xl-5" id="about" style="height: fit-content; background-color: #C8D9EE;">
#   <div class="container" style="margin-bottom: 5rem;">
#     <div class="row align-items-center">
#       <div class="col-lg-6 order-lg-2 order-2">
#         <div class="p-2" style="display:  flex; justify-content: center;"><img class="rounded-circle img-fluid" height="90%" width="90%" src="https://ik.imagekit.io/maysentg/rails-portfolio/self-avatar.png" alt="cartoon created face of Maysen Greenwood"></div>
#       </div>
#       <div class="col-lg-6 order-lg-1 order-1">
#         <div class="pt-5">
#           <h2 class="display-4">About me</h2>
#           <p>Hey, I'm Maysen, a web developer with a passion for complex, but clean websites. My day job is a Front End Developer for Plus merchants at Shopify, and in my free time I like to do my own personal development on web development frameworks. I'm mainly using Ruby on Rails, but I've learnt frameworks like:</p>
#           <ul>
#             <li>ReactJS</li>
#             <li>NextJS</li>
#             <li>Astro</li>
#           </ul>
#         </div>
#       </div>
#     </div>
#   </div>
# </section>
# <!-- Projects section -->
# <section class="py-4 py-xl-5" id="projects" style="background-color: #F4F6FC;">
#   <div class="container">
#     <div class="row align-items-center">
#       <div class="order-lg-2">
#         <div class="pt-5">
#           <h2 class="display-4">My projects</h2>
#           <p>I've been focussing on functional projects such as advanced todo apps, an online store, or live code editors. My key strengths are Ruby on Rails, and the use of relational databases and tools like Redis (which caches/renders this website).</p>
#           <br>
#           <p>This portfolio website was built with Ruby on Rails, and because the frontend code files are hosted in a DB table, I can make adjustments to the code immediately without redeploying the app</p>
#         </div>
#       </div>
#     </div> 
#     <div class="row">
#       <ul class="project__list" id="ul-projects-container-ajax" data-masonry="{ &quot;itemSelector&quot;: &quot;.project&quot;, &quot;columnWidth&quot;: 200 }"><li class="project"><div class="project__wrapper"><img src="https://ik.imagekit.io/maysentg/rails-portfolio/tewi5tlhtxe2ib0a08el5ap89qvu" class="project__img" width="100%" height="100%" alt="Compound Growth Calculator"><div class="project__description"><h3 class="project__description--title">Compound Growth Calculator</h3><h4 class="project__description--sub-title">NodeJS, ChartJS, HTML, CSS</h4><p class="project__description--para">This is an app which visually shows the effects of compound growth. Graph is using ChartJS.</p><div class="project__description--links"><a href="https://github.com/MaysenTG/Compound-Growth-JS-App" rel="noreferrer" target="_blank" class="project__description--link"><img alt="github icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/github-logo-white.png" height="30px" width="30px" class="icon"></a><a href="https://maysentg.github.io/Compound-Growth-JS-App/" rel="noreferrer" target="_blank" class="project__description--link"><img alt="web preview icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/website-logo-white.png" height="30px" width="30px" class="icon"></a></div></div></div></li><li class="project"><div class="project__wrapper"><img src="https://ik.imagekit.io/maysentg/rails-portfolio/ddtzhojoxcrbbgel59yyf2e749uz" class="project__img" width="100%" height="100%" alt="Rails todo app with users"><div class="project__description"><h3 class="project__description--title">Rails todo app with users</h3><h4 class="project__description--sub-title">Ruby on Rails, PostgreSQL, Bootstrap</h4><p class="project__description--para">This is a todo app styled using Bootstrap. The website allows users to create accounts, and create todo items which are only available to that specific user</p><div class="project__description--links"><a href="https://github.com/MaysenTG/login_rails_todolist" rel="noreferrer" target="_blank" class="project__description--link"><img alt="github icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/github-logo-white.png" height="30px" width="30px" class="icon"></a><a href="https://custom-rails-todo-app.herokuapp.com/" rel="noreferrer" target="_blank" class="project__description--link"><img alt="web preview icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/website-logo-white.png" height="30px" width="30px" class="icon"></a></div></div></div></li><li class="project"><div class="project__wrapper"><img src="https://ik.imagekit.io/maysentg/rails-portfolio/rawy0byop8bpyb7vohpjj1gu7eyd" class="project__img" width="100%" height="100%" alt="Online store"><div class="project__description"><h3 class="project__description--title">Online store</h3><h4 class="project__description--sub-title">Ruby on Rails, PostgreSQL</h4><p class="project__description--para">An Ecommerce stored powered using Ruby on Rails. The "admin" can login</p><div class="project__description--links"><a href="https://github.com/MaysenTG/rails-online-store" rel="noreferrer" target="_blank" class="project__description--link"><img alt="github icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/github-logo-white.png" height="30px" width="30px" class="icon"></a><a href="https://rails-online-store.herokuapp.com" rel="noreferrer" target="_blank" class="project__description--link"><img alt="web preview icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/website-logo-white.png" height="30px" width="30px" class="icon"></a></div></div></div></li><li class="project"><div class="project__wrapper"><img src="https://ik.imagekit.io/maysentg/rails-portfolio/wybbpo6pv06a3ohai83aspl392lo" class="project__img" width="100%" height="100%" alt="Todo app using a Firebase DB"><div class="project__description"><h3 class="project__description--title">Todo app using a Firebase DB</h3><h4 class="project__description--sub-title">NodeJS, ReactJS, Firebase</h4><p class="project__description--para">This app implements a to do app in ReactJS utilizing CRUD on a Firebase DB</p><div class="project__description--links"><a href="https://github.com/MaysenTG/react-todo-app" rel="noreferrer" target="_blank" class="project__description--link"><img alt="github icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/github-logo-white.png" height="30px" width="30px" class="icon"></a><a href="https://react-todo-app-dusky.vercel.app/" rel="noreferrer" target="_blank" class="project__description--link"><img alt="web preview icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/website-logo-white.png" height="30px" width="30px" class="icon"></a></div></div></div></li><li class="project"><div class="project__wrapper"><img src="https://ik.imagekit.io/maysentg/rails-portfolio/m12swk3in8sqnjojubgb39e4ixe5" class="project__img" width="100%" height="100%" alt="Live Webpage code editor"><div class="project__description"><h3 class="project__description--title">Live Webpage code editor</h3><h4 class="project__description--sub-title">NodeJS, ReactJS, CodeMirror</h4><p class="project__description--para">This app provides direct feedback to changes in HTML and CSS code by showing a live view of the webpage being edited.</p><div class="project__description--links"><a href="https://github.com/MaysenTG/live-web-code-editor" rel="noreferrer" target="_blank" class="project__description--link"><img alt="github icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/github-logo-white.png" height="30px" width="30px" class="icon"></a><a href="https://maysentg.github.io/live-web-code-editor" rel="noreferrer" target="_blank" class="project__description--link"><img alt="web preview icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/website-logo-white.png" height="30px" width="30px" class="icon"></a></div></div></div></li><li class="project"><div class="project__wrapper"><img src="https://ik.imagekit.io/maysentg/rails-portfolio/z7ref6g0su7z5w5off1rqenak89j" class="project__img" width="100%" height="100%" alt="Link in Bio app"><div class="project__description"><h3 class="project__description--title">Link in Bio app</h3><h4 class="project__description--sub-title">Ruby on Rails, PostgreSQL, User authentication, model relations</h4><p class="project__description--para">A link in bio app similar to LinkTree, LinkPop, Lnk.io. Built using Ruby on Rails and PostgreSQL DB. Link pages are only editable by logging in with the correct details. Users can drag/drop links to change the order.</p><div class="project__description--links"><a href="https://github.com/MaysenTG/rails-link-in-bio" rel="noreferrer" target="_blank" class="project__description--link"><img alt="github icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/github-logo-white.png" height="30px" width="30px" class="icon"></a><a href="https://coral-app-hmvfz.ondigitalocean.app/maysentg" rel="noreferrer" target="_blank" class="project__description--link"><img alt="web preview icon" src="https://ik.imagekit.io/maysentg/tr:w-100,h-100/website-logo-white.png" height="30px" width="30px" class="icon"></a></div></div></div></li></ul>
#     </div>
#   </div>
# </section>
# <!-- Contact section -->
# <section id="contact-me" class="position-relative py-4 py-xl-5" style="height: 100%; background-color: #F5FFEF;">
#   <div class="container" style="margin-top: 5%; margin-bottom: 5%;">
#     <div class="row">
#       <div class="col-lg-6 order-lg-1">
#         <div class="pt-5">
#           <h2 class="display-4">Get in touch</h2>
#           <p>Let me know that you'd like to work with me!</p>
#           <p><a href="mailto:greenwood.maysen@gmail.com">greenwood.maysen@gmail.com</a></p>
#         </div>
#       </div>
#       <div class="col-lg-6 order-lg-2">
#         <div class="pt-5">
#           <div class="mb-5">
#             <div>
#               <div hidden="" id="contact-form-submit" class="alert alert-dismissible fade show" role="alert">
#                 <span id="contact-form-message"></span>
#                 <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
#               </div>
#               <form method="post" action="/contact" id="contact-form">
#                 <div class="mb-3"><input data-display-name="name" id="name-2" class="form-control" type="text" name="user_name" placeholder="Name"></div>
#                 <div class="mb-3"><input data-display-name="email" id="email-2" class="form-control" type="email" name="email" placeholder="Email"></div>
#                 <div class="mb-3"><textarea data-display-name="message" id="message-2" class="form-control" name="message" rows="6" placeholder="Message"></textarea></div>
                
#                 <div>
#                   <button id="submit-form-main-send-btn" class="btn btn-primary d-block w-100" type="submit">Send me a message!</button>
#                   <button id="submit-form-loading" class="d-block w-100 btn btn-primary hidden" type="button" disabled="">
#                     <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
#                     Sending...
#                   </button>
#                 </div>
# 				<div style="opacity: 0;"><input data-display-name="message" id="address" class="form-control" name="address" placeholder="Address"></div>
#               </form>
#             </div>
#           </div>
#         </div>
#       </div>
#     </div>
#   </div>
# </section>
#     </main>
#     <footer>
#       <footer style="background-color: #050A30 !important" class="p-4 d-flex flex-wrap justify-content-between align-items-center">
#   <div class="col-md-4 d-flex align-items-center">
#     <a href="/" class="text-muted text-decoration-none lh-1">
# 		Maysen Greenwood
#     </a>
#     <span class="text-muted">© 2022 Company, Inc</span>
#   </div>
  
#   <ul class="nav col-md-4 justify-content-end list-unstyled d-flex">
#     <li class="ms-3"><a target="_blank" rel="noreferrer noopener" class="text-muted" href="https://github.com/MaysenTG"><i class="bi-github"></i></a></li>
#     <li class="ms-3"><a target="_blank" rel="noreferrer noopener" class="text-muted" href="https://www.linkedin.com/in/maysen-greenwood/"><i class="bi-linkedin"></i></a></li>
#     <li class="ms-3"><a target="_blank" rel="noreferrer noopener" class="text-muted" href="https://www.facebook.com/maysen.greenwood"><i class="bi-facebook"></i></a></li>
#   </ul>
# </footer>
#     </footer>
#     <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0/dist/js/bootstrap.bundle.min.js" integrity="sha384-A3rJD856KowSb7dwlZdYEkO39Gagi7vIsF0jrRAoQmDKKtQBHUuLZ9AsSv4jD4Xa" crossorigin="anonymous"></script>
#     <script>
#       function removeActiveFromAllA() {
#         let allActiveA = document.querySelectorAll("a[href^='#'].active")
#         try {
#           allActiveA.forEach((eachA) => {
#             eachA.classList.remove("active");
#           });
#           } catch(e) {
            
#           }
#       }   
            
#       function updateActiveNavLink(target_href) {
#        removeActiveFromAllA();
#        try {
#          document.querySelector("[href='"+"#"+target_href+"']").classList.add("active"); 
#        } catch(e) {}
#       }
         
#       // Loop through the buttons and add the active class to the current/clicked button
#       fetch(`${window.location.origin}/api/projects/all`).then(data => data.json()).then(data => window.Projects = data).then(data => generateProjectsLi());
            
#       document.addEventListener('DOMContentLoaded', function () {      
#             //fetch("api/projects/all").then(data => data.json()).then(data => window.Projects = data).then(data => generateProjectsLi());
        
#         let current_path = window.location.href.split("#")[1];
#         if(current_path != undefined){
#       updateActiveNavLink(current_path);
#         }
#       });
#     </script>
#     <style>.projects__container{display:flex;padding:75px 0;width:100%;margin:0 auto;justify-content:center}.project{margin-bottom:120px;max-width:35rem;display:flex;margin-left:1rem;margin-right:1rem}.project__img{width:100%;max-width:35rem;transition:all .5s ease;margin:0 auto}.project__wrapper{display:flex;box-shadow:0 2px 10px rgba(0,0,0,.45);overflow:hidden;position:relative}.row{margin:0 auto;padding:0 6px}.project__list{width:100%;padding-top:40px;display:flex;justify-content:space-evenly;flex-wrap:wrap}.project__wrapper:before{content:"";position:absolute;top:0;left:0;height:100%;width:100%;background-color:#1c1d25;opacity:0;transition:all 450ms ease;z-index:2;transform:translateY(100%)}.project:hover .project__wrapper:before{transform:translateY(0);opacity:.7}.project:hover .project__img{transform:scale(1.07);filter:blur(5px)}.project:hover .project__description{opacity:1;transform:translateY(-50%)}.project__description{position:absolute;top:50%;left:50px;padding-right:30px;transform:translateY(100%);max-width:550px;z-index:3;opacity:0;transition:transform 450ms,opacity .3s}.project__description--title{font-size:1.4rem}.project__description--para{font-size:0.9rem;margin:14px 0}.project__description--link{font-size:1rem;margin-right:16px;text-decoration:none}.project__description--sub-title{font-size:1.1rem}.project__description--link,.project__description--para,.project__description--sub-title,.project__description--title{text-align:left;color:#fff}[data-custom-class=body],[data-custom-class=body] *{background:0 0!important}[data-custom-class=title],[data-custom-class=title] *{font-family:Arial!important;font-size:26px!important;color:#000!important}[data-custom-class=subtitle],[data-custom-class=subtitle] *{font-family:Arial!important;color:#595959!important;font-size:14px!important}[data-custom-class=heading_1],[data-custom-class=heading_1] *{font-family:Arial!important;font-size:19px!important;color:#000!important}[data-custom-class=heading_2],[data-custom-class=heading_2] *{font-family:Arial!important;font-size:17px!important;color:#000!important}[data-custom-class=body_text],[data-custom-class=body_text] *{color:#595959!important;font-size:14px!important;font-family:Arial!important}[data-custom-class=link],[data-custom-class=link] *{color:#3030f1!important;font-size:14px!important;font-family:Arial!important;word-break:break-word!important}@media only screen and (max-width:1100px){.project-image{width:22rem;height:12rem}.project-container{width:22rem}}@media only screen and (max-width:570px){.project__description--title{font-size:1.2rem}.project__description--sub-title{font-size:.9rem}.project__description--para{font-size:.8rem}.icon{font-size:25px}.project__description{left:30px}}@media only screen and (max-width:450px){.project__description--title{font-size:1.1rem}.project__description--sub-title{font-size:.9rem}.project__description--para{font-size:.8rem;margin:7px 0}.project{margin-bottom:60px}}.nav-link{font-size:1.2rem}p, span, a, h2, h3, button{font-family: 'Work Sans', sans-serif !important}.icon{height: 30px}.active{color: #F5FFEF !important}.project{margin-bottom: 55px}.bi{color: white}.sticky-nav{position: fixed;top: 0;width: 100%;z-index: 10}.coolMainButton{border: 2px solid currentColor;background-color: #F4F6FC;border-radius: 0.5rem;font-size: 4rem;font-weight: 100;overflow: hidden;padding: 1rem 2rem;position: relative;text-decoration: none;transition: 1s transform ease-in-out;z-index: 0}.coolMainButton::after{background-color: #050A30;border-radius: 0.5rem;content: '';display: block;height: 100%;width: 100%;position: absolute;left: 0;top: 0;transform: translate(-100%, 0) rotate(10deg);transform-origin: top left;transition: .4s transform ease-out;z-index: -1}.coolMainButton:hover::after{transform: translate(0, 0)}.coolMainButton:hover{border: 2px solid transparent;color: #F4F6FC;transform: scale(1.05)}.form-control{background-color: #F4F6FC}.hidden{display: none !important}.hero-section-contents > h1{font-size: 100px;text-align: left;color: #F4F6FC;font-family: 'Public Sans', sans-serif}.hero-section-contents > p{font-size: 35px;text-align: left;color: #F4F6FC}.hero-section-contents.hero-subtext{font-size: 24px;text-align: left;color: #F4F6FC}@media only screen and (max-width: 1020px){.hero-section-contents > h1{font-size: 85px}}@media only screen and (max-width: 905px){.hero-section-contents > h1{font-size: 75px}}@media only screen and (max-width: 767px){nav.navbar{backdrop-filter: "blur(5px)" !important;background: "rgba(5, 10, 48, 0.7)" !important}}@media only screen and (max-width: 790px){.hero-section-contents{margin: 0 10px}.hero-section-contents > h1{font-size: 55px}.hero-section-contents > p{font-size: 25px}}

# .error {
#   border: 2px solid red;
# }

# nav {
#   transition: background 300ms linear 0s;
#   transition: backdrop-filter 300ms linear 0s;
# }</style>
#     }
    
#     template = %{
#       <html lang="en"><head>
#     <!-- Google tag (gtag.js) -->
#     <script type="text/javascript" async="" src="https://www.google-analytics.com/analytics.js"></script><script type="text/javascript" async="" src="https://www.googletagmanager.com/gtag/js?id=UA-210024160-1&amp;l=dataLayer&amp;cx=c"></script><script async="" src="https://www.googletagmanager.com/gtag/js?id=G-GHP62XN5TQ"></script>
#     <script>
#       window.dataLayer = window.dataLayer || [];
#       function gtag(){dataLayer.push(arguments);}
#       gtag('js', new Date());
      
#       gtag('config', 'G-GHP62XN5TQ');
#     </script>
#     <!-- End Google tag (gtag.js) -->
#     <title>Maysen Greenwoods Personal Portfolio</title>
#     <meta name="viewport" content="width=device-width, initial-scale=1">
#     <meta name="description" content="Personal portfolio site for Maysen Greenwood. Maysen Greenwood is a developer with expertise in frontend and backend website development. Backend frameworks include Ruby on Rails, NodeJS and NextJS. Frontend frameworks include ReactJS, Astro. Maysen Greenwood also has extensive experience with Shopify Liquid coding">
#     <meta name="keywords" content="maysen, greenwood, mason, greenwood, maysen greenwood, mason greenwood, programming, front end developer, developer, ruby on rails, ruby, Shopify, Liquid, backend, frontend">
#     <meta name="”robots”" content="”index," follow”="">
#     <meta property="og:type" content="article">
#     <meta property="og:title" content="Maysen Greenwoods Personal Portfolio">
#     <meta property="og:description" content="Personal portfolio site for Maysen Greenwood. Maysen Greenwood is a developer with expertise in frontend and backend website development. Backend frameworks include Ruby on Rails, NodeJS and NextJS. Frontend frameworks include ReactJS, Astro. Maysen Greenwood also has extensive experience with Shopify Liquid coding">
#     <meta property="og:url" content="https://maysengreenwood.com">
#     <meta property="og:site_name" content="Maysen Greenwood's Personal Portfolio">
#     <meta charset="utf-8">
#     <link rel="canonical" href="https://maysengreenwood.com">
#     <link rel="icon" type="image/x-icon" href="https://ik.imagekit.io/maysentg/tr:w-25,h-25/self-portrait.jpg">
#     <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-gH2yIJqKdNHPEq0n4Mqa/HGKIhSkIHeL5AyhkYV8i59U5AR6csBvApHHNl/vI1Bx" crossorigin="anonymous">
    
#     <link rel="preconnect" href="https://fonts.googleapis.com">
#     <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="">
#     <link href="https://fonts.googleapis.com/css2?family=Public+Sans:wght@700;800&amp;family=Work+Sans&amp;display=swap" rel="stylesheet">
#     <script type="text/javascript">
#       window.onload = function() {
#         let alreadyHadError = false;
        
#         document.getElementById('contact-form').addEventListener('submit', function(event) {
#           event.preventDefault();
          
#           let emailInputs = document.querySelectorAll("form#contact-form > div > input:not([id='address']), textarea");
#           let hasErrors = false;
          
#           emailInputs.forEach(input => {
#             if(input.value == "" || input.value == null) {
#             	hasErrors = true;
#             	if(!input.classList.contains('error')) {
#                   input.classList.add("error");
#                   var vowelRegex = '^[aieouAIEOU].*'
#                   var matched = input.dataset.displayName.match(vowelRegex)
#             // A little overkill, but ensures the text uses "an" or "a" depending on whether the input starts with a vowel
#                   if(matched) {
#                         input.parentElement.insertAdjacentHTML("beforeEnd", `
#                       <div style="display: block; font-weight: bold; font-size: 1em;" class="invalid-feedback">
#                             Please enter an ${input.dataset.displayName}
#                         </div>`);
#                   } else {
#                     input.parentElement.insertAdjacentHTML("beforeEnd", `
#                         <div style="display: block; font-weight: bold; font-size: 1em;" class="invalid-feedback">
#                               Please enter a ${input.dataset.displayName}
#                           </div>`);
#                   }
#                 }
#           	} else {
#             	input.classList.remove("error");
#                 if(input.nextElementSibling != null) {
#                   input.nextElementSibling.remove();
#                 }
#           	}
#           })
          
#             if(hasErrors) {
#             //alreadyHadError = true;
#             	return;  
#             }
            
#           document.querySelector("#submit-form-loading").classList.remove("hidden");
#           document.querySelector("#submit-form-main-send-btn").classList.add("hidden")
            
      
#           var contact_name = event.target.user_name.value;
#           var contact_email = event.target.email.value;
#           var contact_message = event.target.message.value;
#           var contact_address_hp = event.target.address.value;
#           var data = {
#             name: contact_name,
#             email: contact_email,
#             message: contact_message,
#             address: contact_address_hp
#           }
          
#           sendEmail(data).then((response) => {
#             console.log(response)
#             if(response.status == 200) {
#               handleEmailSubmitUI("success")
#             } else {
#               handleEmailSubmitUI("fail")
#             }
#           })
#         });
#       }
      
#       async function sendEmail(emailBody) {
#         let response = await fetch("/contact", {
#       method: 'POST',
#             headers: {
#               'Content-Type': 'application/json'
#             },
#       body: JSON.stringify(emailBody)
#       });
#         return response;
#       }
      
#       function handleEmailSubmitUI(status) {
#         document.querySelector("#submit-form-loading").classList.add("hidden");
#         document.querySelector("#submit-form-main-send-btn").classList.remove("hidden");
#         document.querySelector("#contact-form-submit").removeAttribute("hidden");
#         let alert_type = "";
#         let final_message = "";
        
#         if(status == "success") {
#           final_message = "Email successfully sent"
#           alert_type = "alert-success"
#           document.querySelector("#contact-form").reset()
#         } else {
#           final_message = "Email failed, please try again"
#           alert_type = "alert-danger"
#         }
        
#         document.querySelector("#contact-form-message").innerText = final_message;
#         document.querySelector("#contact-form-submit").classList.add(alert_type);
#       }
#     </script>
#     <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.9.1/font/bootstrap-icons.css">
#   </head>
#   <body> 
#   <%= content_for_layout %>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     </script>
#   </body>
  

# </body></html>
#     }.gsub(/^  /, '')
    
#     rhtml = ERB.new(template)
    
#     html = rhtml.result(binding)
    
    
#     render html: html.html_safe
    
#     # Using Ruby ERB, render the html
    

    # Get data from the https://cdn.maysengreenwood.com/index.html URL
    # Parse the data into a Ruby object
    # Render the data into the view
    
    
    # content = Net::HTTP.get_response(URI.parse("https://cdn.maysengreenwood.com/all.html")).body
    # render html: content.html_safe
  end
end
