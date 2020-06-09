server:
	gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 8 --timeout 0 django_cloudrun.wsgi:application


worker:
	celery -A django-cloudrun worker -l info
