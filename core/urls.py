from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def health(request):
    return JsonResponse({'status': 'OK', 'service': 'JTrack JDash'})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health, name='health'),
    path('api/', include('core.urls')),
    path('', include('core.urls')),
]
