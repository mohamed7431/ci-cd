from django.urls import path
from . import views

urlpatterns = [
    # UI
    path('', views.home, name='home'),

    # API
    path('status/', views.api_status, name='api_status'),
    path('studies/', views.api_studies, name='api_studies'),
]
