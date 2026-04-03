from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def health(request):
    return JsonResponse({'status': 'OK', 'service': 'JTrack JDash'})

urlpatterns = [
    path('admin/', admin.site.urls),

    # Health check (for Docker / Load Balancer)
    path('health/', health, name='health'),

    # API routes
    path('api/', include('core.urls')),

    # Optional: root URL → you can point to a homepage view later
]
