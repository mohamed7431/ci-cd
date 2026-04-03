from django.urls import path
from . import views

urlpatterns = [
    # Example endpoints — update based on your project

    path('', views.home, name='home'),  # optional root
    path('status/', views.status, name='status'),

    # Add your actual APIs here
]
