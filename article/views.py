from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.contrib.auth.decorators import login_required
from article.models import Post
from datetime import datetime

# Create your views here.

def index(request):
    posts = Post.objects.all()
    now = datetime.now()
    return render(request, "index.html", {'posts': posts, 'now': now})

@login_required
def create_post(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        slug = request.POST.get('slug')
        content = request.POST.get('content')
        
        if title and slug and content:
            post = Post(
                title=title,
                slug=slug,
                content=content,
                author=request.user
            )
            post.save()
            return redirect('index')
            
    return render(request, "article/create_post.html")