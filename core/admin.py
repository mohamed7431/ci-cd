from django.contrib import admin
from .models import Study, Subject


@admin.register(Study)
class StudyAdmin(admin.ModelAdmin):
    list_display = ['name', 'status', 'created_by', 'created_at']
    list_filter = ['status']
    search_fields = ['name', 'description']


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ['subject_id', 'study', 'is_active', 'enrolled_at']
    list_filter = ['is_active', 'study']
    search_fields = ['subject_id']
