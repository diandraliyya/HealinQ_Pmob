import '../models/models.dart';

class AppData {
  // Mock Counselors
  static List<CounselorModel> counselors = [
    CounselorModel(
      id: 1,
      name: 'Dr. Diandra Aliyya Khoirunisa, M.Psi',
      specialization: 'Psikolog Klinis',
      rating: 5.0,
      type: 'Both',
      location: 'Jl. Mawar Melati No.123, Surabaya',
      bio: 'Psikolog klinis berpengalaman yang berfokus pada manajemen stres dan kecemasan.',
      yearsExperience: 8,
      priceOnline: 150000,
      priceOffline: 200000,
      isVerified: true,
      isAvailable: true,
    ),
    CounselorModel(
      id: 2,
      name: 'Dr. Jessica Atalya Kriswianto, M.Psi',
      specialization: 'Stress Management',
      rating: 4.5,
      type: 'Online',
      location: 'Online',
      bio: 'Spesialis manajemen stres dan konseling remaja.',
      yearsExperience: 5,
      priceOnline: 120000,
      priceOffline: 0,
      isVerified: true,
      isAvailable: true,
    ),
    CounselorModel(
      id: 3,
      name: 'Dr. Leon Kennedy, M.Psi',
      specialization: 'Anxiety & Depression',
      rating: 4.8,
      type: 'Both',
      location: 'Jl. Raya Darmo No.45, Surabaya',
      bio: 'Ahli dalam penanganan kecemasan dan depresi ringan hingga sedang.',
      yearsExperience: 10,
      priceOnline: 175000,
      priceOffline: 225000,
      isVerified: true,
      isAvailable: false,
    ),
    CounselorModel(
      id: 4,
      name: 'Dr. Maudy Ayunda, M.Psi',
      specialization: 'Self-Development',
      rating: 4.7,
      type: 'Both',
      location: 'Jl. Pemuda No.12, Surabaya',
      bio: 'Fokus pada pengembangan diri dan potensi personal.',
      yearsExperience: 6,
      priceOnline: 130000,
      priceOffline: 180000,
      isVerified: true,
      isAvailable: true,
    ),
    CounselorModel(
      id: 5,
      name: 'Dr. Ethan Winters, M.Psi',
      specialization: 'Trauma Healing',
      rating: 4.9,
      type: 'Offline',
      location: 'Jl. Basuki Rahmat No.88, Surabaya',
      bio: 'Spesialis trauma healing dan pemulihan emosional.',
      yearsExperience: 12,
      priceOnline: 0,
      priceOffline: 250000,
      isVerified: true,
      isAvailable: false,
    ),
    CounselorModel(
      id: 6,
      name: 'Dr. Lily Winters, M.Psi',
      specialization: 'Relationship Counseling',
      rating: 4.6,
      type: 'Both',
      location: 'Jl. Diponegoro No.33, Surabaya',
      bio: 'Konseling hubungan dan komunikasi interpersonal.',
      yearsExperience: 7,
      priceOnline: 140000,
      priceOffline: 190000,
      isVerified: true,
      isAvailable: false,
    ),
    CounselorModel(
      id: 7,
      name: 'Dr. Lady Dimitrescu, M.Psi',
      specialization: 'Child & Adolescent',
      rating: 4.4,
      type: 'Both',
      location: 'Jl. Rungkut No.55, Surabaya',
      bio: 'Psikolog anak dan remaja berpengalaman.',
      yearsExperience: 9,
      priceOnline: 160000,
      priceOffline: 210000,
      isVerified: true,
      isAvailable: false,
    ),
  ];

  // Mock Passion Questions - diperbanyak supaya bisa diacak
  static List<PassionQuestion> passionQuestions = [
    PassionQuestion(id: 1, questionText: 'Seberapa sering Anda menikmati memecahkan teka-teki atau masalah rumit?'),
    PassionQuestion(id: 2, questionText: 'Seberapa sering Anda menikmati membuat karya seni atau kreatif?'),
    PassionQuestion(id: 3, questionText: 'Seberapa sering Anda menikmati membantu orang lain yang membutuhkan?'),
    PassionQuestion(id: 4, questionText: 'Seberapa sering Anda menikmati belajar hal-hal baru tentang teknologi?'),
    PassionQuestion(id: 5, questionText: 'Seberapa sering Anda menikmati berbicara dan berinteraksi dengan banyak orang?'),
    PassionQuestion(id: 6, questionText: 'Seberapa sering Anda menikmati aktivitas fisik atau olahraga?'),
    PassionQuestion(id: 7, questionText: 'Seberapa sering Anda menikmati membaca atau menulis cerita?'),
    PassionQuestion(id: 8, questionText: 'Seberapa sering Anda menikmati mengelola atau mengorganisir sesuatu?'),
    PassionQuestion(id: 9, questionText: 'Seberapa sering Anda menikmati penelitian atau eksperimen ilmiah?'),
    PassionQuestion(id: 10, questionText: 'Seberapa sering Anda menikmati kegiatan bisnis atau berwirausaha?'),
    PassionQuestion(id: 11, questionText: 'Seberapa sering Anda menikmati mengajar atau berbagi pengetahuan?'),
    PassionQuestion(id: 12, questionText: 'Seberapa sering Anda menikmati mendesain sesuatu agar terlihat lebih menarik?'),
    PassionQuestion(id: 13, questionText: 'Seberapa sering Anda menikmati memimpin kelompok kecil atau tim?'),
    PassionQuestion(id: 14, questionText: 'Seberapa sering Anda menikmati mendengarkan curhatan orang lain?'),
    PassionQuestion(id: 15, questionText: 'Seberapa sering Anda menikmati membuat strategi atau rencana?'),
    PassionQuestion(id: 16, questionText: 'Seberapa sering Anda menikmati mencoba ide baru?'),
    PassionQuestion(id: 17, questionText: 'Seberapa sering Anda menikmati bekerja dengan angka atau data?'),
    PassionQuestion(id: 18, questionText: 'Seberapa sering Anda menikmati membuat konten visual atau digital?'),
  ];

  // Mock Jar of Happiness Items
  static List<Map<String, String>> jarItems = [
    {'type': 'affirmation', 'content': 'Kamu sudah melakukan yang terbaik hari ini! 🌟'},
    {'type': 'affirmation', 'content': 'Setiap langkah kecil adalah kemajuan yang berarti 💪'},
    {'type': 'question', 'content': 'Apa 3 hal yang kamu syukuri hari ini?'},
    {'type': 'affirmation', 'content': 'Kamu berharga dan dicintai ❤️'},
    {'type': 'question', 'content': 'Apa yang membuat kamu tersenyum hari ini?'},
    {'type': 'affirmation', 'content': 'Perasaanmu valid dan penting 🌸'},
    {'type': 'question', 'content': 'Siapa orang yang ingin kamu hubungi hari ini?'},
    {'type': 'affirmation', 'content': 'Hari ini, kamu sudah cukup berani! 🦋'},
    {'type': 'challenge', 'content': 'Challenge: Minum 8 gelas air hari ini! 💧'},
    {'type': 'affirmation', 'content': 'Masa sulit ini pasti berlalu 🌈'},
    {'type': 'question', 'content': 'Apa mimpi yang ingin kamu kejar tahun ini?'},
    {'type': 'challenge', 'content': 'Challenge: Hubungi satu teman yang sudah lama tidak disapa 📱'},
  ];

  // Banyak lyric untuk FYP
  static List<Map<String, String>> lyrics = [
    {
      'title': 'Who Knows',
      'artist': 'Daniel Caesar',
      'lyric':
          '"You\'re Pure, You\'re Kind Mature, Divine You Might Be Too Good For Me, Unattainable (Let Me Know, Let Me Know, Let Me Know, Let Me)"',
    },
    {
      'title': 'Fight Song',
      'artist': 'Rachel Platten',
      'lyric': '"This is my fight song, take back my life song, prove I\'m alright song..."',
    },
    {
      'title': 'Scars To Your Beautiful',
      'artist': 'Alessia Cara',
      'lyric': '"You should know you\'re beautiful just the way you are..."',
    },
    {
      'title': 'Rise Up',
      'artist': 'Andra Day',
      'lyric': '"And I\'ll rise up, I\'ll rise like the day..."',
    },
    {
      'title': 'Brave',
      'artist': 'Sara Bareilles',
      'lyric': '"Say what you wanna say and let the words fall out..."',
    },
  ];

  // Lyric otomatis ganti tiap hari
  static Map<String, String> get lyricOfTheDay {
    final now = DateTime.now();
    final index = (now.year + now.month + now.day) % lyrics.length;
    return lyrics[index];
  }

  // Mock Journals
  static List<JournalModel> journals = [
    JournalModel(
      id: 1,
      title: 'I Hate My Life Lately...',
      content: 'Hari ini terasa sangat berat. Banyak hal yang menumpuk dan aku merasa overwhelmed.',
      moodTag: '😔',
      createdAt: DateTime.now(),
    ),
    JournalModel(
      id: 2,
      title: 'Finally, I Found My Passion...',
      content: 'Setelah mengisi kuis FYP, aku menemukan bahwa passionku ada di bidang pendidikan dan seni!',
      moodTag: '😊',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    JournalModel(
      id: 3,
      title: 'People Always Leave. Don\'t Get...',
      content: 'Perasaan ini terus menghantui. Tapi aku tahu aku harus terus maju.',
      moodTag: '😢',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    JournalModel(
      id: 4,
      title: 'A Little Better Today',
      content: 'Hari ini aku mencoba bernapas lebih pelan dan menulis apa yang aku rasakan.',
      moodTag: '😌',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];
}