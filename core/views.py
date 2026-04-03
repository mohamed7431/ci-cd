from django.shortcuts import render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from .models import Study, Subject


def home(request):
    """JDash home page — shows study overview."""
    context = {
        'study_count': Study.objects.count(),
        'subject_count': Subject.objects.count(),
        'active_studies': Study.objects.filter(status='active').count(),
    }
    return render(request, 'core/home.html', context)


@api_view(['GET'])
@permission_classes([AllowAny])
def api_status(request):
    """Public API status endpoint."""
    return Response({
        'status': 'running',
        'service': 'JTrack JDash',
        'version': '1.0.0',
        'studies': Study.objects.count(),
        'subjects': Subject.objects.count(),
    })


@api_view(['GET'])
def api_studies(request):
    """List all studies."""
    studies = Study.objects.values(
        'id', 'name', 'description', 'status', 'created_at'
    )
    return Response(list(studies))
