from django.db import models
from django.contrib.auth.models import User


class Study(models.Model):
    """Represents a JTrack digital health study."""
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('paused', 'Paused'),
        ('closed', 'Closed'),
    ]

    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = 'Studies'
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class Subject(models.Model):
    """A participant enrolled in a study."""
    study = models.ForeignKey(Study, on_delete=models.CASCADE, related_name='subjects')
    subject_id = models.CharField(max_length=100, unique=True)
    enrolled_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f'{self.subject_id} ({self.study.name})'
