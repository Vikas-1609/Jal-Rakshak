/// A YouTube video showing how a fix is done.
class TutorialVideo {
  const TutorialVideo(this.id, this.title, this.channel, this.duration);

  final String id, title, channel, duration;

  Uri get watchUrl => Uri.https('www.youtube.com', '/watch', {'v': id});
  String get thumbnailUrl => 'https://i.ytimg.com/vi/$id/mqdefault.jpg';
}

enum TutorialTopic { bunds, trenches, reveg }

/// Hand-picked videos per fix and language. Each was checked on YouTube
/// (Nov 2026): it exists, allows embedding, and is spoken in that language
/// per YouTube's auto captions. Titles are shortened from the originals.
const tutorialVideos = <String, Map<TutorialTopic, List<TutorialVideo>>>{
  'en': {
    TutorialTopic.bunds: [
      TutorialVideo(
        'CkKYVwapsBM',
        'Contour bunds',
        'Access Agriculture',
        '4:00',
      ),
      TutorialVideo('r4mIeOGmq0E', 'Contour bunds', 'AgVid', '1:11'),
    ],
    TutorialTopic.trenches: [
      TutorialVideo(
        'gKR0Qu4MRWU',
        'Contour & staggered trenches: field tutorial',
        'EcoPractical Studio',
        '6:42',
      ),
      TutorialVideo(
        'ir7HwZK_7Qg',
        'How to construct contour trenches (English subtitles)',
        'Paani Foundation',
        '13:47',
      ),
    ],
    TutorialTopic.reveg: [
      TutorialVideo(
        'c2kJvqRTI-o',
        'Grass strips against soil erosion',
        'Access Agriculture',
        '2:18',
      ),
      TutorialVideo(
        'gnb3hUOAeHo',
        'Vetiver grass: stop erosion and build topsoil',
        'Practical Primate',
        '7:44',
      ),
    ],
  },
  'hi': {
    TutorialTopic.bunds: [
      TutorialVideo(
        'XTkLsUZ4AWA',
        'खेत में मेड़बंदी करने का आसान तरीका',
        'पंकज की किसान पाठशाला',
        '2:44',
      ),
      TutorialVideo(
        '0kGHDBscyaI',
        'कंटूर मेड़ और ढालू मेड़: खेत में प्रदर्शन',
        'Amit Bhatnagar Classes',
        '10:30',
      ),
    ],
    TutorialTopic.trenches: [
      TutorialVideo(
        'DO16HZEQ4Nk',
        'मनरेगा में स्टैगर्ड कंटूर ट्रेंच',
        'Odisha MGNREGS',
        '4:10',
      ),
      TutorialVideo(
        'RmbEideoFrc',
        'ट्रेंच क्या है, कितने प्रकार के होते हैं',
        'AKTGURU',
        '3:19',
      ),
    ],
    TutorialTopic.reveg: [
      TutorialVideo(
        'DrMr-mZTNP0',
        'खस घास से मिट्टी का कटाव रोकें',
        'DW हिन्दी',
        '2:42',
      ),
      TutorialVideo(
        'daYoUYj3XGg',
        'पहाड़ी इलाकों में मिट्टी का कटाव रोकने वाले पौधे',
        'News18 Bihar Jharkhand',
        '6:08',
      ),
    ],
  },
};
