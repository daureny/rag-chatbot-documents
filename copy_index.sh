#!/bin/bash
# Скрипт для копирования индекса с Google Drive на persistent storage Render

echo "Начинаем копирование индекса..."

# Используем Python для скачивания и распаковки
python3 -c "
import urllib.request
import os
import subprocess
import zipfile
import shutil

print('Скачиваем файл с Google Drive...')
try:
    urllib.request.urlretrieve('https://drive.google.com/uc?export=download&id=13w_RsfyJ6m1sbPEZle_tM8EFPxZv3vwT', '/tmp/index.zip')
    print('Файл успешно скачан')
except Exception as e:
    print(f'Ошибка при скачивании: {e}')
    exit(1)

print('Распаковываем архив...')
try:
    with zipfile.ZipFile('/tmp/index.zip', 'r') as zip_ref:
        zip_ref.extractall('/tmp')
    print('Архив успешно распакован')
except Exception as e:
    print(f'Ошибка при распаковке: {e}')
    exit(1)

print('Создаем директорию для индекса...')
os.makedirs('/data/faiss_index', exist_ok=True)

print('Копируем все файлы в директорию persistent storage...')
try:
    src_dir = '/tmp/index'
    dst_dir = '/data/faiss_index'

    # Получаем список файлов
    files = os.listdir(src_dir)
    print(f'Найдено файлов для копирования: {len(files)}')

    # Копируем каждый файл
    for file in files:
        src_file = os.path.join(src_dir, file)
        dst_file = os.path.join(dst_dir, file)
        if os.path.isfile(src_file):
            shutil.copy2(src_file, dst_file)
            print(f'Скопирован файл: {file}')
        elif os.path.isdir(src_file):
            if os.path.exists(dst_file):
                shutil.rmtree(dst_file)
            shutil.copytree(src_file, dst_file)
            print(f'Скопирована директория: {file}')

    print('Все файлы успешно скопированы')
except Exception as e:
    print(f'Ошибка при копировании файлов: {e}')
    exit(1)

print('Проверяем содержимое директории индекса:')
for file in os.listdir(dst_dir):
    file_path = os.path.join(dst_dir, file)
    file_size = os.path.getsize(file_path) if os.path.isfile(file_path) else 'директория'
    print(f'{file}: {file_size} байт')
"

echo "Индекс успешно скопирован!"