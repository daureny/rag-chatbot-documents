cat > copy_index.py << 'EOL'
#!/usr/bin/env python3
import os
import urllib.request
import urllib.parse
import re
import zipfile
import shutil

print("Начинаем копирование индекса...")

# Функция для правильного скачивания с Google Drive
def download_file_from_google_drive(id, destination):
    def get_confirm_token(response):
        for key, value in response.info().items():
            if key.lower() == "set-cookie":
                for part in value.split(';'):
                    if part.startswith('download_warning'):
                        return part.split('=')[1]
        return None

    URL = "https://docs.google.com/uc?export=download"
    
    session = urllib.request.build_opener()
    params = {'id': id}
    url = URL + "?" + urllib.parse.urlencode(params)
    
    print(f"Запрашиваем файл по URL: {url}")
    response = session.open(url)
    token = get_confirm_token(response)

    if token:
        params = {'id': id, 'confirm': token}
        url = URL + "?" + urllib.parse.urlencode(params)
        print(f"Получен токен, запрашиваем повторно с токеном: {url}")
        response = session.open(url)

    print("Начинаем скачивание файла...")
    CHUNK_SIZE = 32768
    with open(destination, "wb") as f:
        while True:
            chunk = response.read(CHUNK_SIZE)
            if not chunk:
                break
            f.write(chunk)
    
    print(f"Файл сохранен в: {destination}")
    return destination

try:
    file_id = "13w_RsfyJ6m1sbPEZle_tM8EFPxZv3vwT"
    destination = "/tmp/index.zip"
    
    print(f"Скачиваем файл с Google Drive (ID: {file_id})...")
    download_file_from_google_drive(file_id, destination)
    
    # Проверка, что файл скачался
    if os.path.exists(destination):
        size = os.path.getsize(destination)
        print(f"Файл скачан успешно. Размер: {size} байт")
    else:
        print("Ошибка: файл не был скачан")
        exit(1)
    
    # Проверка, что файл действительно ZIP
    with open(destination, 'rb') as f:
        header = f.read(4)
        if header != b'PK\x03\x04':
            print("Предупреждение: скачанный файл не имеет сигнатуры ZIP. Проверяем содержимое файла...")
            with open(destination, 'rb') as f:
                start = f.read(100)
                print(f"Начало файла: {start}")
            print("Попробуем другой метод скачивания...")
            
            # Альтернативный метод скачивания
            alt_url = f"https://drive.google.com/uc?id={file_id}&export=download"
            print(f"Пробуем скачать через: {alt_url}")
            urllib.request.urlretrieve(alt_url, destination)
            
            # Проверяем снова
            with open(destination, 'rb') as f:
                header = f.read(4)
                if header != b'PK\x03\x04':
                    print("Ошибка: файл всё ещё не является ZIP-архивом.")
                    exit(1)
                
    print("Распаковываем архив...")
    try:
        with zipfile.ZipFile(destination, 'r') as zip_ref:
            zip_ref.extractall('/tmp')
        print('Архив успешно распакован')
    except Exception as e:
        print(f'Ошибка при распаковке: {e}')
        exit(1)
    
    # Проверяем содержимое распакованного архива
    print("Проверяем распакованные файлы:")
    for root, dirs, files in os.walk('/tmp'):
        for d in dirs:
            if d == 'index':
                index_dir = os.path.join(root, d)
                print(f"Найдена директория индекса: {index_dir}")
                print("Содержимое директории:")
                for f in os.listdir(index_dir):
                    print(f"- {f}")
    
    # Проверяем наличие директории с индексом
    if not os.path.exists('/tmp/index'):
        print("Ошибка: директория index не найдена после распаковки.")
        
        # Ищем директорию, которая может содержать индекс
        for root, dirs, files in os.walk('/tmp'):
            for file in files:
                if file.endswith('.faiss'):
                    print(f"Найден файл .faiss: {os.path.join(root, file)}")
                    os.makedirs('/tmp/index', exist_ok=True)
                    shutil.copy2(os.path.join(root, file), '/tmp/index/')
                    print(f"Скопирован файл {file} в /tmp/index/")
        
        # Если всё ещё нет директории, выходим
        if not os.path.exists('/tmp/index'):
            print("Не удалось найти файлы индекса после распаковки.")
            exit(1)
    
    print("Создаем директорию для индекса...")
    os.makedirs('/data/faiss_index', exist_ok=True)
    
    print("Копируем все файлы в директорию persistent storage...")
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
    
except Exception as e:
    print(f"Произошла ошибка: {e}")
    exit(1)

print("Индекс успешно скопирован!")
EOL

python3 copy_index.py