import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';

class AppStrings {
  final UserLanguage lang;

  AppStrings(this.lang);

  // Home Screen
  String get resetSetup => {
        UserLanguage.korean: '초기 설정으로 돌아가기 (개발용)',
        UserLanguage.english: 'Reset to Initial Setup (Dev)',
        UserLanguage.japanese: '初期設定に戻す（開発用）',
        UserLanguage.chinese: '返回初始设置（开发用）',
        UserLanguage.spanish: 'Restablecer configuración inicial (Dev)',
        UserLanguage.french: 'Réinitialiser la configuration (Dev)',
      }[lang] ?? '초기 설정으로 돌아가기 (개발용)';

  String get historyTitle => {
        UserLanguage.korean: '번역 기록',
        UserLanguage.english: 'Translation History',
        UserLanguage.japanese: '翻訳履歴',
        UserLanguage.chinese: '翻译历史',
        UserLanguage.spanish: 'Historial de traducción',
        UserLanguage.french: 'Historique des traductions',
      }[lang] ?? '번역 기록';

  String get favoritesTitle => {
        UserLanguage.korean: '즐겨찾기',
        UserLanguage.english: 'Favorites',
        UserLanguage.japanese: 'お気に入り',
        UserLanguage.chinese: '收藏夹',
        UserLanguage.spanish: 'Favoritos',
        UserLanguage.french: 'Favoris',
      }[lang] ?? '즐겨찾기';

  String get chooseNativeLanguage => {
        UserLanguage.korean: '어떤 언어를 사용하시나요?\n(Choose your native language)',
        UserLanguage.english: 'Which language do you use?\n(Choose your native language)',
        UserLanguage.japanese: '何語を使用しますか？\n(Choose your native language)',
        UserLanguage.chinese: '您使用哪种语言？\n(Choose your native language)',
        UserLanguage.spanish: '¿Qué idioma hablas?\n(Choose your native language)',
        UserLanguage.french: 'Quelle langue parlez-vous ?\n(Choose your native language)',
      }[lang] ?? '어떤 언어를 사용하시나요?\n(Choose your native language)';

  String get chooseTravelCountry => {
        UserLanguage.korean: '어느 나라를 여행하고 있나요?',
        UserLanguage.english: 'Which country are you traveling to?',
        UserLanguage.japanese: 'どの国を旅行していますか？',
        UserLanguage.chinese: '您正在哪个国家旅行？',
        UserLanguage.spanish: '¿A qué país vas a viajar?',
        UserLanguage.french: 'Dans quel pays voyagez-vous ?',
      }[lang] ?? '어느 나라를 여행하고 있나요?';

  String get cameraActionTitle => {
        UserLanguage.korean: '카메라로 촬영하여 번역하기',
        UserLanguage.english: 'Translate with Camera',
        UserLanguage.japanese: 'カメラで撮影して翻訳',
        UserLanguage.chinese: '用相机拍摄翻译',
        UserLanguage.spanish: 'Traducir con la cámara',
        UserLanguage.french: 'Traduire avec l\'appareil photo',
      }[lang] ?? '카메라로 촬영하여 번역하기';

  String get cameraActionDesc => {
        UserLanguage.korean: '사진을 촬영하여 텍스트를 감지하고 번역합니다.',
        UserLanguage.english: 'Take a photo to detect and translate text.',
        UserLanguage.japanese: '写真を撮影してテキストを検出・翻訳します。',
        UserLanguage.chinese: '拍摄照片以检测并翻译文本。',
        UserLanguage.spanish: 'Haz una foto para detectar y traducir el texto.',
        UserLanguage.french: 'Prenez une photo pour détecter et traduire le texte.',
      }[lang] ?? '사진을 촬영하여 텍스트를 감지하고 번역합니다.';

  String get galleryActionTitle => {
        UserLanguage.korean: '갤러리에서 이미지 가져오기',
        UserLanguage.english: 'Import from Gallery',
        UserLanguage.japanese: 'ギャラリーからインポート',
        UserLanguage.chinese: '从相册导入图片',
        UserLanguage.spanish: 'Importar de la galería',
        UserLanguage.french: 'Importer de la galerie',
      }[lang] ?? '갤러리에서 이미지 가져오기';

  String get galleryActionDesc => {
        UserLanguage.korean: '앨범에서 사진을 선택하여 번역합니다.',
        UserLanguage.english: 'Select a photo from your album to translate.',
        UserLanguage.japanese: 'アルバムから写真を選択して翻訳します。',
        UserLanguage.chinese: '从相册中选择照片进行翻译。',
        UserLanguage.spanish: 'Selecciona una foto de tu álbum para traducirla.',
        UserLanguage.french: 'Sélectionnez une photo de votre album pour la traduire.',
      }[lang] ?? '앨범에서 사진을 선택하여 번역합니다.';

  String get travelLanguageSetting => {
        UserLanguage.korean: '여행지 언어 설정',
        UserLanguage.english: 'Travel Destination Language',
        UserLanguage.japanese: '旅行先の言語設定',
        UserLanguage.chinese: '目的地语言设置',
        UserLanguage.spanish: 'Idioma del destino de viaje',
        UserLanguage.french: 'Langue de la destination',
      }[lang] ?? '여행지 언어 설정';

  String get myLanguageSetting => {
        UserLanguage.korean: '나의 언어 설정',
        UserLanguage.english: 'My Language Setting',
        UserLanguage.japanese: 'マイ言語設定',
        UserLanguage.chinese: '我的语言设置',
        UserLanguage.spanish: 'Mi configuración de idioma',
        UserLanguage.french: 'Mon paramètre de langue',
      }[lang] ?? '나의 언어 설정';

  String get travelDestinationLanguage => {
        UserLanguage.korean: '여행 대상 언어',
        UserLanguage.english: 'Destination Language',
        UserLanguage.japanese: '旅行対象の言語',
        UserLanguage.chinese: '目标旅行语言',
        UserLanguage.spanish: 'Idioma de destino',
        UserLanguage.french: 'Langue cible',
      }[lang] ?? '여행 대상 언어';

  String get userLanguageLabel => {
        UserLanguage.korean: '사용 언어',
        UserLanguage.english: 'My Language',
        UserLanguage.japanese: '使用言語',
        UserLanguage.chinese: '使用语言',
        UserLanguage.spanish: 'Mi idioma',
        UserLanguage.french: 'Ma langue',
      }[lang] ?? '사용 언어';

  String get startBtn => {
        UserLanguage.korean: '시작하기',
        UserLanguage.english: 'Get Started',
        UserLanguage.japanese: 'スタート',
        UserLanguage.chinese: '开始使用',
        UserLanguage.spanish: 'Comenzar',
        UserLanguage.french: 'Démarrer',
      }[lang] ?? '시작하기';

  String get selectDoneBtn => {
        UserLanguage.korean: '선택 완료',
        UserLanguage.english: 'Done',
        UserLanguage.japanese: '選択完了',
        UserLanguage.chinese: '选择完成',
        UserLanguage.spanish: 'Confirmar',
        UserLanguage.french: 'Terminé',
      }[lang] ?? '선택 완료';

  // Text Selection Screen
  String get selectRegionTitle => {
        UserLanguage.korean: '번역할 영역 선택',
        UserLanguage.english: 'Select Region to Translate',
        UserLanguage.japanese: '翻訳する領域を選択',
        UserLanguage.chinese: '选择翻译区域',
        UserLanguage.spanish: 'Seleccionar región a traducir',
        UserLanguage.french: 'Sélectionner la zone à traduire',
      }[lang] ?? '번역할 영역 선택';

  String get selectRegionDesc => {
        UserLanguage.korean: '텍스트를 터치하거나 드래그하여 영역을 선택하세요.',
        UserLanguage.english: 'Tap or drag to select the text area.',
        UserLanguage.japanese: 'テキストをタップまたはドラッグして領域を選択してください。',
        UserLanguage.chinese: '点击或拖拽以选择文本区域。',
        UserLanguage.spanish: 'Toca o arrastra para seleccionar el área de texto.',
        UserLanguage.french: 'Appuyez ou glissez pour sélectionner la zone de texte.',
      }[lang] ?? '텍스트를 터치하거나 드래그하여 영역을 선택하세요.';

  String get analyzeBtn => {
        UserLanguage.korean: '분석하기',
        UserLanguage.english: 'Analyze',
        UserLanguage.japanese: '분석する',
        UserLanguage.chinese: '分析',
        UserLanguage.spanish: 'Analizar',
        UserLanguage.french: 'Analyser',
      }[lang] ?? '분석하기';

  String get analyzingState => {
        UserLanguage.korean: '분석 중...',
        UserLanguage.english: 'Analyzing...',
        UserLanguage.japanese: '分析中...',
        UserLanguage.chinese: '分析中...',
        UserLanguage.spanish: 'Analizando...',
        UserLanguage.french: 'Analyse en cours...',
      }[lang] ?? '분석 중...';

  String get noTextDetected => {
        UserLanguage.korean: '텍스트를 감지하지 못했습니다.',
        UserLanguage.english: 'No text detected.',
        UserLanguage.japanese: 'テキストが検出されませんでした。',
        UserLanguage.chinese: '未检测到文本。',
        UserLanguage.spanish: 'No se ha detectado texto.',
        UserLanguage.french: 'Aucun texte détecté.',
      }[lang] ?? '텍스트를 감지하지 못했습니다.';

  String get backBtn => {
        UserLanguage.korean: '뒤로',
        UserLanguage.english: 'Back',
        UserLanguage.japanese: '戻る',
        UserLanguage.chinese: '返回',
        UserLanguage.spanish: 'Volver',
        UserLanguage.french: 'Retour',
      }[lang] ?? '뒤로';

  // Result Screen
  String get analysisResultTitle => {
        UserLanguage.korean: '분석 결과',
        UserLanguage.english: 'Analysis Result',
        UserLanguage.japanese: '分析結果',
        UserLanguage.chinese: '分析结果',
        UserLanguage.spanish: 'Resultado del análisis',
        UserLanguage.french: 'Résultat de l\'analyse',
      }[lang] ?? '분석 결과';

  String get originalTextLabel => {
        UserLanguage.korean: '원본 텍스트',
        UserLanguage.english: 'Original Text',
        UserLanguage.japanese: '原文',
        UserLanguage.chinese: '原文',
        UserLanguage.spanish: 'Texto original',
        UserLanguage.french: 'Texte d\'origine',
      }[lang] ?? '원본 텍스트';

  String get translationLabel => {
        UserLanguage.korean: '번역',
        UserLanguage.english: 'Translation',
        UserLanguage.japanese: '翻訳',
        UserLanguage.chinese: '翻译',
        UserLanguage.spanish: 'Traducción',
        UserLanguage.french: 'Traduction',
      }[lang] ?? '번역';

  String get explanationLabel => {
        UserLanguage.korean: '단어 설명 및 맥락',
        UserLanguage.english: 'Vocabulary & Context',
        UserLanguage.japanese: '単語の説明と文脈',
        UserLanguage.chinese: '词汇解释与背景',
        UserLanguage.spanish: 'Vocabulario y contexto',
        UserLanguage.french: 'Vocabulaire & Contexte',
      }[lang] ?? '단어 설명 및 맥락';

  String get allergyInfoLabel => {
        UserLanguage.korean: '알레르기 유발 성분 및 주의사항',
        UserLanguage.english: 'Allergy Information & Warnings',
        UserLanguage.japanese: 'アレルギー情報・注意事項',
        UserLanguage.chinese: '过敏原信息与注意事项',
        UserLanguage.spanish: 'Información y advertencias de alergias',
        UserLanguage.french: 'Allergènes et avertissements',
      }[lang] ?? '알레르기 유발 성분 및 주의사항';

  String get copiedToClipboard => {
        UserLanguage.korean: '클립보드에 복사되었습니다.',
        UserLanguage.english: 'Copied to clipboard.',
        UserLanguage.japanese: 'クリップボードにコピーされました。',
        UserLanguage.chinese: '已复制到剪贴板。',
        UserLanguage.spanish: 'Copiado al portapapeles.',
        UserLanguage.french: 'Copié dans le presse-papiers.',
      }[lang] ?? '클립보드에 복사되었습니다.';

  String get selectFavFolderTitle => {
        UserLanguage.korean: '즐겨찾기 폴더 선택',
        UserLanguage.english: 'Select Favorite Folder',
        UserLanguage.japanese: 'お気に入りフォルダを選択',
        UserLanguage.chinese: '选择收藏文件夹',
        UserLanguage.spanish: 'Seleccionar carpeta de favoritos',
        UserLanguage.french: 'Sélectionner le dossier favori',
      }[lang] ?? '즐겨찾기 폴더 선택';

  String get newFavFolderTitle => {
        UserLanguage.korean: '새 즐겨찾기 폴더',
        UserLanguage.english: 'New Favorite Folder',
        UserLanguage.japanese: '新しいお気に入りフォルダ',
        UserLanguage.chinese: '新建收藏文件夹',
        UserLanguage.spanish: 'Nueva carpeta de favoritos',
        UserLanguage.french: 'Nouveau dossier favori',
      }[lang] ?? '새 즐겨찾기 폴더';

  String get folderNameLabel => {
        UserLanguage.korean: '폴더 이름',
        UserLanguage.english: 'Folder Name',
        UserLanguage.japanese: 'フォルダ名',
        UserLanguage.chinese: '文件夹名称',
        UserLanguage.spanish: 'Nombre de la carpeta',
        UserLanguage.french: 'Nom du dossier',
      }[lang] ?? '폴더 이름';

  String get addNewFolderBtn => {
        UserLanguage.korean: '새 폴더 추가',
        UserLanguage.english: 'Add New Folder',
        UserLanguage.japanese: '新規フォルダ追加',
        UserLanguage.chinese: '添加新文件夹',
        UserLanguage.spanish: 'Añadir nueva carpeta',
        UserLanguage.french: 'Ajouter un dossier',
      }[lang] ?? '새 폴더 추가';

  String get orderPhraseTitle => {
        UserLanguage.korean: '현지 주문 예문',
        UserLanguage.english: 'Local Order Phrase',
        UserLanguage.japanese: '現地での注文例',
        UserLanguage.chinese: '当地点单例句',
        UserLanguage.spanish: 'Ejemplo de pedido local',
        UserLanguage.french: 'Exemple de commande locale',
      }[lang] ?? '현지 주문 예문';

  String get orderPhrasePronunciationLabel => {
        UserLanguage.korean: '발음',
        UserLanguage.english: 'Pronunciation',
        UserLanguage.japanese: '発音',
        UserLanguage.chinese: '发音',
        UserLanguage.spanish: 'Pronunciación',
        UserLanguage.french: 'Prononciation',
      }[lang] ?? '발음';

  String get orderPhraseMeaningLabel => {
        UserLanguage.korean: '뜻',
        UserLanguage.english: 'Meaning',
        UserLanguage.japanese: '意味',
        UserLanguage.chinese: '意思',
        UserLanguage.spanish: 'Significado',
        UserLanguage.french: 'Signification',
      }[lang] ?? '뜻';

  String get tipsTitle => {
        UserLanguage.korean: '현지 이용 꿀팁',
        UserLanguage.english: 'Local Travel Tips',
        UserLanguage.japanese: '現地利用のコツ',
        UserLanguage.chinese: '当地实用贴士',
        UserLanguage.spanish: 'Consejos útiles de viaje',
        UserLanguage.french: 'Conseils utiles locaux',
      }[lang] ?? '현지 이용 꿀팁';

  String get retryBtn => {
        UserLanguage.korean: '다시 시도',
        UserLanguage.english: 'Retry',
        UserLanguage.japanese: 'もう一度試す',
        UserLanguage.chinese: '重试',
        UserLanguage.spanish: 'Reintentar',
        UserLanguage.french: 'Réessayer',
      }[lang] ?? '다시 시도';

  String get createBtn => {
        UserLanguage.korean: '만들기',
        UserLanguage.english: 'Create',
        UserLanguage.japanese: '作成',
        UserLanguage.chinese: '创建',
        UserLanguage.spanish: 'Crear',
        UserLanguage.french: 'Créer',
      }[lang] ?? '만들기';

  String get folderHintText => {
        UserLanguage.korean: '예: 맛집 탐방, 교통 수단',
        UserLanguage.english: 'e.g., Food tour, Transit',
        UserLanguage.japanese: '例：グルメ巡り、交通機関',
        UserLanguage.chinese: '例如：美食探店、交通工具',
        UserLanguage.spanish: 'ej. Ruta gastronómica, Transporte',
        UserLanguage.french: 'ex. Tournée gourmande, Transport',
      }[lang] ?? '예: 맛집 탐방, 교통 수단';

  String get emojiSelectionLabel => {
        UserLanguage.korean: '아이콘 이모지 선택',
        UserLanguage.english: 'Select Icon Emoji',
        UserLanguage.japanese: 'アイコンの絵文字を選択',
        UserLanguage.chinese: '选择图标表情',
        UserLanguage.spanish: 'Selecciona un emoji para el icono',
        UserLanguage.french: 'Sélectionner un emoji',
      }[lang] ?? '아이콘 이모지 선택';

  String get imageLoadError => {
        UserLanguage.korean: '이미지를 표시할 수 없습니다',
        UserLanguage.english: 'Cannot display image',
        UserLanguage.japanese: '画像を表示できません',
        UserLanguage.chinese: '无法显示图片',
        UserLanguage.spanish: 'No se puede mostrar la imagen',
        UserLanguage.french: 'Impossible d\'afficher l\'image',
      }[lang] ?? '이미지를 표시할 수 없습니다';

  String get imageMissingDesc => {
        UserLanguage.korean: '원본 사진 파일이 삭제되었거나 존재하지 않습니다.',
        UserLanguage.english: 'The original photo file has been deleted or does not exist.',
        UserLanguage.japanese: '元の写真파일이 삭제된가, 존재하지 않습니다.',
        UserLanguage.chinese: '原始照片文件已被删除或不存在。',
        UserLanguage.spanish: 'El archivo de imagen original se ha eliminado o no existe.',
        UserLanguage.french: 'Le fichier image d\'origine a été supprimé ou n\'existe pas.',
      }[lang] ?? '원본 사진 파일이 삭제되었거나 존재하지 않습니다.';

  String get analyzingText => {
        UserLanguage.korean: 'Gemini AI 분석 중...',
        UserLanguage.english: 'Gemini AI Analyzing...',
        UserLanguage.japanese: 'Gemini AI 分析중...',
        UserLanguage.chinese: 'Gemini AI 分析中...',
        UserLanguage.spanish: 'Gemini AI analizando...',
        UserLanguage.french: 'Analyse Gemini AI...',
      }[lang] ?? 'Gemini AI 분석 중...';

  String get analyzingDesc => {
        UserLanguage.korean: '세로쓰기와 손글씨를 판독하고 있습니다.\n잠시만 기다려 주세요.',
        UserLanguage.english: 'Reading text, vertical layouts, and handwriting.\nPlease wait a moment.',
        UserLanguage.japanese: '縦書きや手書き文字を解読しています。\n少々お待ちください。',
        UserLanguage.chinese: '正在识别竖排文本和手写体。\n请稍候。',
        UserLanguage.spanish: 'Detectando texto vertical y manuscrito.\nPor favor, espera un momento.',
        UserLanguage.french: 'Lecture de texte vertical et d\'écriture manuscrite.\nVeuillez patienter.',
      }[lang] ?? '세로쓰기와 손글씨를 판독하고 있습니다.\n잠시만 기다려 주세요.';

  String get errorAnalyzing => {
        UserLanguage.korean: '분석 중 오류 발생',
        UserLanguage.english: 'Error during analysis',
        UserLanguage.japanese: '分析中にエラーが発生しました',
        UserLanguage.chinese: '分析时发生错误',
        UserLanguage.spanish: 'Error durante el análisis',
        UserLanguage.french: 'Erreur lors de l\'analyse',
      }[lang] ?? '분석 중 오류 발생';

  String get cancelBtn => {
        UserLanguage.korean: '취소',
        UserLanguage.english: 'Cancel',
        UserLanguage.japanese: 'キャンセル',
        UserLanguage.chinese: '取消',
        UserLanguage.spanish: 'Cancelar',
        UserLanguage.french: 'Annuler',
      }[lang] ?? '취소';

  String get addBtn => {
        UserLanguage.korean: '추가',
        UserLanguage.english: 'Add',
        UserLanguage.japanese: '追加',
        UserLanguage.chinese: '添加',
        UserLanguage.spanish: 'Añadir',
        UserLanguage.french: 'Ajouter',
      }[lang] ?? '추가';

  String get addedToFavs => {
        UserLanguage.korean: '즐겨찾기에 추가되었습니다.',
        UserLanguage.english: 'Added to favorites.',
        UserLanguage.japanese: 'お気に入りに追加されました。',
        UserLanguage.chinese: '已添加到收藏夹。',
        UserLanguage.spanish: 'Añadido a favoritos.',
        UserLanguage.french: 'Ajouté aux favoris.',
      }[lang] ?? '즐겨찾기에 추가되었습니다.';

  String get removedFromFavs => {
        UserLanguage.korean: '즐겨찾기에서 제거되었습니다.',
        UserLanguage.english: 'Removed from favorites.',
        UserLanguage.japanese: 'お気に入りから削除されました。',
        UserLanguage.chinese: '已从收藏夹中移除。',
        UserLanguage.spanish: 'Eliminado de favoritos.',
        UserLanguage.french: 'Retiré des favoris.',
      }[lang] ?? '즐겨찾기에서 제거되었습니다.';

  // Favorites Screen
  String get emptyFavoritesTitle => {
        UserLanguage.korean: '즐겨찾기가 비어 있습니다.',
        UserLanguage.english: 'Favorites is empty.',
        UserLanguage.japanese: 'お気に入りは空です。',
        UserLanguage.chinese: '收藏夹为空。',
        UserLanguage.spanish: 'No hay favoritos.',
        UserLanguage.french: 'Aucun favori.',
      }[lang] ?? '즐겨찾기가 비어 있습니다.';

  String get emptyFavoritesDesc => {
        UserLanguage.korean: '분석 결과에서 별표(★)를 눌러\n폴더별로 번역 단어들을 모아보세요!',
        UserLanguage.english: 'Tap the star (★) on translation results\nto organize items in folders!',
        UserLanguage.japanese: '翻訳結果の星（★）をタップして\nフォルダごとにお気に入りを整理しましょう！',
        UserLanguage.chinese: '点击翻译结果上的星号（★）\n将内容按文件夹分类收藏！',
        UserLanguage.spanish: '¡Toca la estrella (★) en los resultados\npara organizar los elementos por carpetas!',
        UserLanguage.french: 'Appuyez sur l\'étoile (★) dans les résultats\npour organiser vos mots par dossiers !',
      }[lang] ?? '분석 결과에서 별표(★)를 눌러\n폴더별로 번역 단어들을 모아보세요!';

  String itemsCount(int count) {
    return {
          UserLanguage.korean: '항목 $count개',
          UserLanguage.english: '$count items',
          UserLanguage.japanese: '$count個の項目',
          UserLanguage.chinese: '$count个项目',
          UserLanguage.spanish: '$count elementos',
          UserLanguage.french: '$count éléments',
        }[lang] ??
        '항목 $count개';
  }

  String get emptyFolderDesc => {
        UserLanguage.korean: '이 폴더에 저장된 항목이 없습니다.',
        UserLanguage.english: 'No items saved in this folder.',
        UserLanguage.japanese: 'このフォルダには保存された項目がありません。',
        UserLanguage.chinese: '该文件夹中没有已保存的项目。',
        UserLanguage.spanish: 'No hay elementos guardados en esta carpeta.',
        UserLanguage.french: 'Aucun élément enregistré dans ce dossier.',
      }[lang] ?? '이 폴더에 저장된 항목이 없습니다.';

  String removedFromFolder(String folderName) {
    return {
          UserLanguage.korean: '$folderName에서 삭제되었습니다.',
          UserLanguage.english: 'Removed from $folderName.',
          UserLanguage.japanese: '$folderNameから削除されました。',
          UserLanguage.chinese: '已从 $folderName 中删除。',
          UserLanguage.spanish: 'Eliminado de $folderName.',
          UserLanguage.french: 'Retiré de $folderName.',
        }[lang] ??
        '$folderName에서 삭제되었습니다.';
  }

  // History Screen
  String get searchPlaceholder => {
        UserLanguage.korean: '검색어 입력...',
        UserLanguage.english: 'Search...',
        UserLanguage.japanese: '検索...',
        UserLanguage.chinese: '搜索...',
        UserLanguage.spanish: 'Buscar...',
        UserLanguage.french: 'Rechercher...',
      }[lang] ?? '검색어 입력...';

  String get clearAllBtn => {
        UserLanguage.korean: '전체 삭제',
        UserLanguage.english: 'Clear All',
        UserLanguage.japanese: 'すべて削除',
        UserLanguage.chinese: '清除全部',
        UserLanguage.spanish: 'Borrar todo',
        UserLanguage.french: 'Tout effacer',
      }[lang] ?? '전체 삭제';

  String get emptyHistoryTitle => {
        UserLanguage.korean: '기록이 비어 있습니다.',
        UserLanguage.english: 'History is empty.',
        UserLanguage.japanese: '履歴は空です。',
        UserLanguage.chinese: '历史记录为空。',
        UserLanguage.spanish: 'No hay historial.',
        UserLanguage.french: 'Aucun historique.',
      }[lang] ?? '기록이 비어 있습니다.';

  String get emptyHistoryDesc => {
        UserLanguage.korean: '카메라나 갤러리에서 번역을 진행하여\n기록을 쌓아보세요!',
        UserLanguage.english: 'Translate with the camera or gallery\nto build up your history!',
        UserLanguage.japanese: '카메라やギャラリーから翻訳を行って\n履歴を蓄積しましょう！',
        UserLanguage.chinese: '用相机或相册进行翻译\n以积累历史记录！',
        UserLanguage.spanish: '¡Traduce con la cámara o desde la galería\npara empezar a guardar tu historial!',
        UserLanguage.french: 'Traduisiez avec l\'appareil photo ou la galerie\npour enrichir votre historique !',
      }[lang] ?? '카메라나 갤러리에서 번역을 진행하여\n기록을 쌓아보세요!';

  String get confirmClearAllTitle => {
        UserLanguage.korean: '기록을 모두 삭제하시겠습니까?',
        UserLanguage.english: 'Delete all history?',
        UserLanguage.japanese: 'すべての履歴を削除しますか？',
        UserLanguage.chinese: '要删除所有历史记录吗？',
        UserLanguage.spanish: '¿Borrar todo el historial?',
        UserLanguage.french: 'Effacer tout l\'historique ?',
      }[lang] ?? '기록을 모두 삭제하시겠습니까?';

  String get deleteBtn => {
        UserLanguage.korean: '삭제',
        UserLanguage.english: 'Delete',
        UserLanguage.japanese: '削除',
        UserLanguage.chinese: '删除',
        UserLanguage.spanish: 'Eliminar',
        UserLanguage.french: 'Supprimer',
      }[lang] ?? '삭제';

  String get allHistoryCleared => {
        UserLanguage.korean: '모든 기록이 삭제되었습니다.',
        UserLanguage.english: 'All history cleared.',
        UserLanguage.japanese: 'すべての履歴が削除されました。',
        UserLanguage.chinese: '所有历史记录已清除。',
        UserLanguage.spanish: 'Se ha borrado todo el historial.',
        UserLanguage.french: 'Tout l\'historique a été effacé.',
      }[lang] ?? '모든 기록이 삭제되었습니다.';

  String get itemDeleted => {
        UserLanguage.korean: '삭제되었습니다.',
        UserLanguage.english: 'Deleted.',
        UserLanguage.japanese: '削除されました。',
        UserLanguage.chinese: '已删除。',
        UserLanguage.spanish: 'Eliminado.',
        UserLanguage.french: 'Supprimé.',
      }[lang] ?? '삭제되었습니다.';

  String get galleryActionSubtitle => {
        UserLanguage.korean: '저장된 이미지에서 번역!',
        UserLanguage.english: 'Translate from saved images!',
        UserLanguage.japanese: '保存された画像から翻訳！',
        UserLanguage.chinese: '从保存的图片中翻译！',
        UserLanguage.spanish: '¡Traduce desde imágenes guardadas!',
        UserLanguage.french: 'Traduisez à partir d\'images enregistrées !',
      }[lang] ?? 'Translate from saved images!';

  String get geminiPoweredFooter => {
        UserLanguage.korean: 'Gemini 기반 텍스트 인식 및 번역',
        UserLanguage.english: 'Gemini-powered text recognition & translation',
        UserLanguage.japanese: 'Geminiベース of テキスト認識と翻訳',
        UserLanguage.chinese: '基于 Gemini 的文本识别与翻译',
        UserLanguage.spanish: 'Reconocimiento y traducción de texto con tecnología Gemini',
        UserLanguage.french: 'Reconnaissance et traduction de texte via Gemini',
      }[lang] ?? 'Gemini-powered text recognition & translation';

  String _getLangNameForDestination(LanguageMode targetLang) {
    return {
      UserLanguage.korean: {
        LanguageMode.french: '프랑스어',
        LanguageMode.spanish: '스페인어',
        LanguageMode.english: '영어',
        LanguageMode.japanese: '일본어',
        LanguageMode.chinese: '중국어',
      },
      UserLanguage.english: {
        LanguageMode.french: 'French',
        LanguageMode.spanish: 'Spanish',
        LanguageMode.english: 'English',
        LanguageMode.japanese: 'Japanese',
        LanguageMode.chinese: 'Chinese',
      },
      UserLanguage.japanese: {
        LanguageMode.french: 'フランス語',
        LanguageMode.spanish: 'スペイン語',
        LanguageMode.english: '英語',
        LanguageMode.japanese: '日本語',
        LanguageMode.chinese: '中国語',
      },
      UserLanguage.chinese: {
        LanguageMode.french: '法语',
        LanguageMode.spanish: '西班牙语',
        LanguageMode.english: '英语',
        LanguageMode.japanese: '日语',
        LanguageMode.chinese: '中文',
      },
      UserLanguage.spanish: {
        LanguageMode.french: 'francés',
        LanguageMode.spanish: 'español',
        LanguageMode.english: 'inglés',
        LanguageMode.japanese: 'japonés',
        LanguageMode.chinese: 'chino',
      },
      UserLanguage.french: {
        LanguageMode.french: 'français',
        LanguageMode.spanish: 'espagnol',
        LanguageMode.english: 'anglais',
        LanguageMode.japanese: 'japonais',
        LanguageMode.chinese: 'chinois',
      },
    }[lang]?[targetLang] ?? targetLang.englishName;
  }

  String languageSubtitle(LanguageMode targetLang) {
    final langName = _getLangNameForDestination(targetLang);
    return {
      UserLanguage.korean: '현지 $langName 메뉴판이 읽기 힘드신가요?\n음식의 이름과 꿀팁을 읽어보세요.',
      UserLanguage.english: 'Is it hard to read local $langName menus?\nRead the food names and tips.',
      UserLanguage.japanese: '現地の$langNameメニューが読みにくいですか？\n料理名やお得な情報を読んでみましょう。',
      UserLanguage.chinese: '看不懂当地的 $langName 菜单吗？\n快来阅读菜名和实用小贴士吧。',
      UserLanguage.spanish: '¿Te cuesta leer el menú local en $langName?\nDescubre los nombres de los platos y consejos útiles.',
      UserLanguage.french: 'Difficultés à lire le menu local en $langName ?\nDécouvrez les noms des plats et des conseils utiles.',
    }[lang] ?? 'Is it hard to read local $langName menus?\nRead the food names and tips.';
  }

  String cameraActionSubtitle(LanguageMode targetLang) {
    final langName = _getLangNameForDestination(targetLang);
    return {
      UserLanguage.korean: '$langName 메뉴를 촬영해 주세요',
      UserLanguage.english: 'Please take a photo of the $langName menu',
      UserLanguage.japanese: '$langNameのメニューを撮影してください',
      UserLanguage.chinese: '请拍摄 $langName 菜单',
      UserLanguage.spanish: 'Por favor, toma una foto del menú en $langName',
      UserLanguage.french: 'Veuillez prendre en photo le menu en $langName',
    }[lang] ?? 'Please take a photo of the $langName menu';
  }

  String get noPhotoSelected => {
        UserLanguage.korean: '선택된 사진이 없습니다.',
        UserLanguage.english: 'No photo selected.',
        UserLanguage.japanese: '選択された写真がありません。',
        UserLanguage.chinese: '没有选择照片。',
        UserLanguage.spanish: 'No se ha seleccionado ninguna foto.',
        UserLanguage.french: 'Aucune photo sélectionnée.',
      }[lang] ?? '선택된 사진이 없습니다.';

  String get textSelectionTitle => {
        UserLanguage.korean: '텍스트 선택',
        UserLanguage.english: 'Select Text',
        UserLanguage.japanese: 'テキスト選択',
        UserLanguage.chinese: '选择文本',
        UserLanguage.spanish: 'Seleccionar texto',
        UserLanguage.french: 'Sélectionner le texte',
      }[lang] ?? '텍스트 선택';

  String textSelectionInstruction(String langName) {
    return {
      UserLanguage.korean: '사진 속 번역을 원하는 $langName 박스를 터치해 선택하세요.',
      UserLanguage.english: 'Tap the $langName box in the photo that you want to translate.',
      UserLanguage.japanese: '写真の中で翻訳したい$langNameの枠をタップして選択してください。',
      UserLanguage.chinese: '点击照片中您想要翻译的 $langName 区域。',
      UserLanguage.spanish: 'Toca la casilla en $langName de la foto que quieras traducir.',
      UserLanguage.french: 'Appuyez sur la zone en $langName de la photo que vous souhaitez traduire.',
    }[lang] ?? 'Tap the $langName box in the photo that you want to translate.';
  }

  String get selectedTextLabel => {
        UserLanguage.korean: '선택된 텍스트',
        UserLanguage.english: 'Selected Text',
        UserLanguage.japanese: '選択されたテキスト',
        UserLanguage.chinese: '已选择文本',
        UserLanguage.spanish: 'Texto seleccionado',
        UserLanguage.french: 'Texte sélectionné',
      }[lang] ?? '선택된 텍스트';

  String get dragAreaInstruction => {
        UserLanguage.korean: '번역하고 싶은 메뉴 영역을 손가락으로 드래그해 보세요.',
        UserLanguage.english: 'Drag your finger over the menu area you want to translate.',
        UserLanguage.japanese: '翻訳したいメニュー領域を指でドラッグしてください。',
        UserLanguage.chinese: '请用手指拖动选择您要翻译的菜单区域。',
        UserLanguage.spanish: 'Arrastra con el dedo sobre el área del menú que deseas traducir.',
        UserLanguage.french: 'Glissez avec votre doigt sur la zone du menu à traduire.',
      }[lang] ?? '번역하고 싶은 메뉴 영역을 손가락으로 드래그해 보세요.';

  String get dragModeTitle => {
        UserLanguage.korean: '영역 드래그',
        UserLanguage.english: 'Drag Area',
        UserLanguage.japanese: '領域ドラッグ',
        UserLanguage.chinese: '拖动区域',
        UserLanguage.spanish: 'Arrastrar área',
        UserLanguage.french: 'Glisser la zone',
      }[lang] ?? '영역 드래그';

  String get rectDragModeTitle => {
        UserLanguage.korean: '사각형',
        UserLanguage.english: 'Rectangle',
        UserLanguage.japanese: '四角形',
        UserLanguage.chinese: '矩形',
        UserLanguage.spanish: 'Rectángulo',
        UserLanguage.french: 'Rectangle',
      }[lang] ?? '사각형';

  String get freeformDragModeTitle => {
        UserLanguage.korean: '자유 곡선',
        UserLanguage.english: 'Freeform',
        UserLanguage.japanese: 'フリーハンド',
        UserLanguage.chinese: '自由手绘',
        UserLanguage.spanish: 'Forma libre',
        UserLanguage.french: 'Forme libre',
      }[lang] ?? '자유 곡선';

  String get rectDragInstruction => {
        UserLanguage.korean: '터치한 시작점에서 대각선으로 드래그하여 사각형을 지정하세요.',
        UserLanguage.english: 'Drag diagonally from your touch point to set the rectangle.',
        UserLanguage.japanese: 'タッチした点から斜めにドラッグして四角形を指定してください。',
        UserLanguage.chinese: '从触摸起点对角拖动以选择矩形区域。',
        UserLanguage.spanish: 'Arrastra en diagonal desde el punto de inicio para el rectángulo.',
        UserLanguage.french: 'Glissez en diagonale depuis le point de départ pour le rectangle.',
      }[lang] ?? '터치한 시작점에서 대각선으로 드래그하여 사각형을 지정하세요.';

  String get freeformDragInstruction => {
        UserLanguage.korean: '손가락으로 원하는 메뉴 영역을 따라 자유롭게 그려보세요.',
        UserLanguage.english: 'Draw freely around the menu area with your finger.',
        UserLanguage.japanese: '指でメニューの周りを自由になぞって描いてください。',
        UserLanguage.chinese: '用手指在菜单周围自由绘制区域。',
        UserLanguage.spanish: 'Dibuja libremente con el dedo alrededor del área del menú.',
        UserLanguage.french: 'Dessinez librement autour de la zone du menu avec votre doigt.',
      }[lang] ?? '손가락으로 원하는 메뉴 영역을 따라 자유롭게 그려보세요.';

  String get panZoomModeTitle => {
        UserLanguage.korean: '확대/이동',
        UserLanguage.english: 'Zoom & Move',
        UserLanguage.japanese: '拡大・移動',
        UserLanguage.chinese: '缩放/移动',
        UserLanguage.spanish: 'Zoom y mover',
        UserLanguage.french: 'Zoom & déplacer',
      }[lang] ?? '확대/이동';

  String get defaultPanZoomInstruction => {
        UserLanguage.korean: '드래그하여 이동 · 두 손가락으로 확대/축소',
        UserLanguage.english: 'Drag to move · Pinch with two fingers to zoom',
        UserLanguage.japanese: 'ドラッグで移動・2本指でピンチズーム',
        UserLanguage.chinese: '单指拖动平移 · 双指捏合缩放',
        UserLanguage.spanish: 'Arrastra para mover · Pellizca con dos dedos para zoom',
        UserLanguage.french: 'Glissez pour déplacer · Pincez à deux doigts pour zoomer',
      }[lang] ?? '드래그하여 이동 · 두 손가락으로 확대/축소';

  String get analyzeSelectedAreaBtn => {
        UserLanguage.korean: '선택한 영역 번역 및 상세 해설',
        UserLanguage.english: 'Translate & Explain Selected Area',
        UserLanguage.japanese: '選択領域を翻訳・解説',
        UserLanguage.chinese: '翻译并解读所选区域',
        UserLanguage.spanish: 'Traducir y explicar área seleccionada',
        UserLanguage.french: 'Traduire et expliquer la zone',
      }[lang] ?? '선택한 영역 번역 및 상세 해설';

  String get autoDetectAllBtn => {
        UserLanguage.korean: '전체 자동 감지',
        UserLanguage.english: 'Auto Detect All',
        UserLanguage.japanese: '全体自動検出',
        UserLanguage.chinese: '全图自动检测',
        UserLanguage.spanish: 'Detección automática total',
        UserLanguage.french: 'Détection automatique',
      }[lang] ?? '전체 자동 감지';

  String get analyzingCropStatus => {
        UserLanguage.korean: 'AI가 선택한 영역의 글씨를 읽고 해설하는 중...',
        UserLanguage.english: 'AI is reading and explaining the selected area...',
        UserLanguage.japanese: 'AIが選択された領域の文字を読み取り解説中...',
        UserLanguage.chinese: 'AI 正在识别并解读所选区域的文本...',
        UserLanguage.spanish: 'La IA está leyendo y explicando el área seleccionada...',
        UserLanguage.french: 'L\'IA analyse la zone sélectionnée...',
      }[lang] ?? 'AI가 선택한 영역의 글씨를 읽고 해설하는 중...';

  String get viewGuideBtn => {
        UserLanguage.korean: '선택한 텍스트 해설 및 가이드 보기',
        UserLanguage.english: 'View Explanation & Guide',
        UserLanguage.japanese: '選択したテキストの解説とガイドを見る',
        UserLanguage.chinese: '查看所选文本的解释和指南',
        UserLanguage.spanish: 'Ver explicación y guía del texto seleccionado',
        UserLanguage.french: 'Voir l\'explication et le guide',
      }[lang] ?? '선택한 텍스트 해설 및 가이드 보기';

  String pleaseSelectBox(String langName) {
    return {
      UserLanguage.korean: '$langName 박스를 선택해 주세요.',
      UserLanguage.english: 'Please select a $langName box.',
      UserLanguage.japanese: '$langNameの枠を選択してください。',
      UserLanguage.chinese: '请选择 $langName 区域。',
      UserLanguage.spanish: 'Por favor, selecciona una casilla en $langName.',
      UserLanguage.french: 'Veuillez sélectionner une zone en $langName.',
    }[lang] ?? 'Please select a $langName box.';
  }

  String detectingText(String langName) {
    return {
      UserLanguage.korean: '$langName 텍스트 감지 중...',
      UserLanguage.english: 'Detecting $langName text...',
      UserLanguage.japanese: '$langNameテキスト検出中...',
      UserLanguage.chinese: '正在检测 $langName 文本...',
      UserLanguage.spanish: 'Detectando texto en $langName...',
      UserLanguage.french: 'Détection du texte en $langName...',
    }[lang] ?? 'Detecting $langName text...';
  }

  String get detectionWaitDesc => {
        UserLanguage.korean: 'AI가 사진 속 글씨 영역들을 찾고 있습니다.\n잠시만 기다려 주세요.',
        UserLanguage.english: 'The AI is searching for text regions in the photo.\nPlease wait a moment.',
        UserLanguage.japanese: 'AIが写真の中の文字領域を探しています。\n少々お待ちください。',
        UserLanguage.chinese: 'AI 正在寻找照片中的文本区域。\n请稍候。',
        UserLanguage.spanish: 'La IA está buscando regiones de texto en la foto.\nPor favor, espera un momento.',
        UserLanguage.french: 'L\'IA recherche des zones de texte sur la photo.\nVeuillez patienter.',
      }[lang] ?? 'AI가 사진 속 글씨 영역들을 찾고 있습니다.\n잠시만 기다려 주세요.';

  String get textDetectionError => {
        UserLanguage.korean: '텍스트 인식 오류',
        UserLanguage.english: 'Text Detection Error',
        UserLanguage.japanese: 'テキスト認識エラー',
        UserLanguage.chinese: '文本识别错误',
        UserLanguage.spanish: 'Error de detección de texto',
        UserLanguage.french: 'Erreur de détection de texte',
      }[lang] ?? '텍스트 인식 오류';
}

final l10nProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(userLanguageProvider);
  return AppStrings(lang);
});
