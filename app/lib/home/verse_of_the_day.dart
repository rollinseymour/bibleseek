/// The curated Verse of the Day pool, in the iOS app's order, so both apps
/// show the same verse on the same day (day of year, Jan 1 = 0, mod 365).
class VerseOfTheDay {
  static ({String ref, String text}) forDate(DateTime d) {
    final doy = DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(d.year)).inDays;
    return pool[doy % pool.length];
  }

  static ({String ref, String text}) get today => forDate(DateTime.now());

  static const pool = <({String ref, String text})>[
    (
      ref: 'John 3:16',
      text:
          'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
    ),
    (
      ref: 'Philippians 4:13',
      text: 'I can do all things through Christ which strengtheneth me.',
    ),
    (
      ref: 'Jeremiah 29:11',
      text:
          'For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.',
    ),
    (
      ref: 'Romans 8:28',
      text:
          'And we know that all things work together for good to them that love God, to them who are the called according to his purpose.',
    ),
    (ref: 'Psalm 23:1', text: 'The LORD is my shepherd; I shall not want.'),
    (
      ref: 'Proverbs 3:5-6',
      text:
          'Trust in the LORD with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.',
    ),
    (
      ref: 'Isaiah 41:10',
      text:
          'Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.',
    ),
    (
      ref: 'Psalm 46:1',
      text: 'God is our refuge and strength, a very present help in trouble.',
    ),
    (
      ref: 'Matthew 11:28',
      text:
          'Come unto me, all ye that labour and are heavy laden, and I will give you rest.',
    ),
    (
      ref: 'Romans 12:2',
      text:
          'And be not conformed to this world: but be ye transformed by the renewing of your mind, that ye may prove what is that good, and acceptable, and perfect, will of God.',
    ),
    (
      ref: 'Psalm 119:105',
      text: 'Thy word is a lamp unto my feet, and a light unto my path.',
    ),
    (
      ref: 'Galatians 5:22-23',
      text:
          'But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith, meekness, temperance: against such there is no law.',
    ),
    (
      ref: 'Hebrews 11:1',
      text:
          'Now faith is the substance of things hoped for, the evidence of things not seen.',
    ),
    (
      ref: '2 Timothy 1:7',
      text:
          'For God hath not given us the spirit of fear; but of power, and of love, and of a sound mind.',
    ),
    (
      ref: 'Psalm 37:4',
      text:
          'Delight thyself also in the LORD; and he shall give thee the desires of thine heart.',
    ),
    (
      ref: '1 Corinthians 13:4-5',
      text:
          'Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself, is not puffed up, doth not behave itself unseemly, seeketh not her own, is not easily provoked, thinketh no evil;',
    ),
    (
      ref: 'Joshua 1:9',
      text:
          'Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.',
    ),
    (
      ref: 'Romans 5:8',
      text:
          'But God commendeth his love toward us, in that, while we were yet sinners, Christ died for us.',
    ),
    (
      ref: 'Ephesians 2:8-9',
      text:
          'For by grace are ye saved through faith; and that not of yourselves: it is the gift of God: Not of works, lest any man should boast.',
    ),
    (
      ref: 'Psalm 91:1-2',
      text:
          'He that dwelleth in the secret place of the most High shall abide under the shadow of the Almighty. I will say of the LORD, He is my refuge and my fortress: my God; in him will I trust.',
    ),
    (
      ref: 'Colossians 3:23',
      text:
          'And whatsoever ye do, do it heartily, as to the Lord, and not unto men.',
    ),
    (
      ref: '1 Peter 5:7',
      text: 'Casting all your care upon him; for he careth for you.',
    ),
    (
      ref: 'Lamentations 3:22-23',
      text:
          'It is of the LORD\'s mercies that we are not consumed, because his compassions fail not. They are new every morning: great is thy faithfulness.',
    ),
    (
      ref: 'Psalm 27:1',
      text:
          'The LORD is my light and my salvation; whom shall I fear? the LORD is the strength of my life; of whom shall I be afraid?',
    ),
    (
      ref: 'Matthew 6:33',
      text:
          'But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.',
    ),
    (
      ref: 'Isaiah 40:31',
      text:
          'But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.',
    ),
    (
      ref: 'Deuteronomy 31:6',
      text:
          'Be strong and of a good courage, fear not, nor be afraid of them: for the LORD thy God, he it is that doth go with thee; he will not fail thee, nor forsake thee.',
    ),
    (
      ref: 'Psalm 34:18',
      text:
          'The LORD is nigh unto them that are of a broken heart; and saveth such as be of a contrite spirit.',
    ),
    (
      ref: 'Romans 15:13',
      text:
          'Now the God of hope fill you with all joy and peace in believing, that ye may abound in hope, through the power of the Holy Ghost.',
    ),
    (
      ref: 'Philippians 4:6-7',
      text:
          'Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God. And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.',
    ),
    (
      ref: 'Matthew 5:6',
      text:
          'Blessed are they which do hunger and thirst after righteousness: for they shall be filled.',
    ),
    (
      ref: 'Proverbs 4:23',
      text:
          'Keep thy heart with all diligence; for out of it are the issues of life.',
    ),
    (
      ref: 'Romans 8:38-39',
      text:
          'For I am persuaded, that neither death, nor life, nor angels, nor principalities, nor powers, nor things present, nor things to come, Nor height, nor depth, nor any other creature, shall be able to separate us from the love of God, which is in Christ Jesus our Lord.',
    ),
    (
      ref: 'Psalm 19:14',
      text:
          'Let the words of my mouth, and the meditation of my heart, be acceptable in thy sight, O LORD, my strength, and my redeemer.',
    ),
    (
      ref: 'Exodus 14:14',
      text: 'The LORD shall fight for you, and ye shall hold your peace.',
    ),
    (
      ref: 'Matthew 5:8',
      text: 'Blessed are the pure in heart: for they shall see God.',
    ),
    (
      ref: 'Proverbs 11:25',
      text:
          'The liberal soul shall be made fat: and he that watereth shall be watered also himself.',
    ),
    (
      ref: '1 Corinthians 10:13',
      text:
          'There hath no temptation taken you but such as is common to man: but God is faithful, who will not suffer you to be tempted above that ye are able; but will with the temptation also make a way to escape, that ye may be able to bear it.',
    ),
    (
      ref: 'Psalm 30:5',
      text:
          'For his anger endureth but a moment; in his favour is life: weeping may endure for a night, but joy cometh in the morning.',
    ),
    (
      ref: 'Numbers 6:24-26',
      text:
          'The LORD bless thee, and keep thee: The LORD make his face shine upon thee, and be gracious unto thee: The LORD lift up his countenance upon thee, and give thee peace.',
    ),
    (
      ref: 'Matthew 5:9',
      text:
          'Blessed are the peacemakers: for they shall be called the children of God.',
    ),
    (
      ref: 'Proverbs 12:25',
      text:
          'Heaviness in the heart of man maketh it stoop: but a good word maketh it glad.',
    ),
    (
      ref: '1 Corinthians 16:14',
      text: 'Let all your things be done with charity.',
    ),
    (
      ref: 'Psalm 51:10',
      text:
          'Create in me a clean heart, O God; and renew a right spirit within me.',
    ),
    (
      ref: 'Isaiah 26:3',
      text:
          'Thou wilt keep him in perfect peace, whose mind is stayed on thee: because he trusteth in thee.',
    ),
    (
      ref: 'Matthew 5:14',
      text:
          'Ye are the light of the world. A city that is set on an hill cannot be hid.',
    ),
    (
      ref: 'Proverbs 13:20',
      text:
          'He that walketh with wise men shall be wise: but a companion of fools shall be destroyed.',
    ),
    (
      ref: '2 Corinthians 5:17',
      text:
          'Therefore if any man be in Christ, he is a new creature: old things are passed away; behold, all things are become new.',
    ),
    (
      ref: 'Psalm 55:22',
      text:
          'Cast thy burden upon the LORD, and he shall sustain thee: he shall never suffer the righteous to be moved.',
    ),
    (
      ref: 'Isaiah 43:2',
      text:
          'When thou passest through the waters, I will be with thee; and through the rivers, they shall not overflow thee: when thou walkest through the fire, thou shalt not be burned; neither shall the flame kindle upon thee.',
    ),
    (
      ref: 'Matthew 5:16',
      text:
          'Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven.',
    ),
    (
      ref: 'Proverbs 14:29',
      text:
          'He that is slow to wrath is of great understanding: but he that is hasty of spirit exalteth folly.',
    ),
    (
      ref: 'Galatians 6:9',
      text:
          'And let us not be weary in well doing: for in due season we shall reap, if we faint not.',
    ),
    (ref: 'Psalm 56:3', text: 'What time I am afraid, I will trust in thee.'),
    (
      ref: 'Micah 6:8',
      text:
          'He hath shewed thee, O man, what is good; and what doth the LORD require of thee, but to do justly, and to love mercy, and to walk humbly with thy God?',
    ),
    (
      ref: 'Matthew 6:34',
      text:
          'Take therefore no thought for the morrow: for the morrow shall take thought for the things of itself. Sufficient unto the day is the evil thereof.',
    ),
    (
      ref: 'Proverbs 15:1',
      text:
          'A soft answer turneth away wrath: but grievous words stir up anger.',
    ),
    (
      ref: 'Ephesians 4:32',
      text:
          'And be ye kind one to another, tenderhearted, forgiving one another, even as God for Christ’s sake hath forgiven you.',
    ),
    (
      ref: 'Psalm 118:24',
      text:
          'This is the day which the LORD hath made; we will rejoice and be glad in it.',
    ),
    (
      ref: 'Nahum 1:7',
      text:
          'The LORD is good, a strong hold in the day of trouble; and he knoweth them that trust in him.',
    ),
    (
      ref: 'Matthew 7:7-8',
      text:
          'Ask, and it shall be given you; seek, and ye shall find; knock, and it shall be opened unto you: For every one that asketh receiveth; and he that seeketh findeth; and to him that knocketh it shall be opened.',
    ),
    (
      ref: 'Proverbs 15:22',
      text:
          'Without counsel purposes are disappointed: but in the multitude of counsellors they are established.',
    ),
    (
      ref: 'Philippians 4:8',
      text:
          'Finally, brethren, whatsoever things are true, whatsoever things are honest, whatsoever things are just, whatsoever things are pure, whatsoever things are lovely, whatsoever things are of good report; if there be any virtue, and if there be any praise, think on these things.',
    ),
    (
      ref: 'Psalm 121:1-2',
      text:
          'I will lift up mine eyes unto the hills, from whence cometh my help. My help cometh from the LORD, which made heaven and earth.',
    ),
    (
      ref: 'Zephaniah 3:17',
      text:
          'The LORD thy God in the midst of thee is mighty; he will save, he will rejoice over thee with joy; he will rest in his love, he will joy over thee with singing.',
    ),
    (
      ref: 'Matthew 7:12',
      text:
          'Therefore all things whatsoever ye would that men should do to you, do ye even so to them: for this is the law and the prophets.',
    ),
    (
      ref: 'Proverbs 16:3',
      text:
          'Commit thy works unto the LORD, and thy thoughts shall be established.',
    ),
    (
      ref: '1 Thessalonians 5:16-18',
      text:
          'Rejoice evermore. Pray without ceasing. In every thing give thanks: for this is the will of God in Christ Jesus concerning you.',
    ),
    (
      ref: 'Psalm 139:14',
      text:
          'I will praise thee; for I am fearfully and wonderfully made: marvellous are thy works; and that my soul knoweth right well.',
    ),
    (
      ref: 'Matthew 18:20',
      text:
          'For where two or three are gathered together in my name, there am I in the midst of them.',
    ),
    (
      ref: 'Proverbs 16:9',
      text: 'A man’s heart deviseth his way: but the LORD directeth his steps.',
    ),
    (
      ref: 'Hebrews 4:16',
      text:
          'Let us therefore come boldly unto the throne of grace, that we may obtain mercy, and find grace to help in time of need.',
    ),
    (
      ref: 'Psalm 147:3',
      text: 'He healeth the broken in heart, and bindeth up their wounds.',
    ),
    (
      ref: 'Matthew 19:26',
      text:
          'But Jesus beheld them, and said unto them, With men this is impossible; but with God all things are possible.',
    ),
    (
      ref: 'Proverbs 17:22',
      text:
          'A merry heart doeth good like a medicine: but a broken spirit drieth the bones.',
    ),
    (
      ref: 'James 1:5',
      text:
          'If any of you lack wisdom, let him ask of God, that giveth to all men liberally, and upbraideth not; and it shall be given him.',
    ),
    (
      ref: 'Matthew 26:41',
      text:
          'Watch and pray, that ye enter not into temptation: the spirit indeed is willing, but the flesh is weak.',
    ),
    (
      ref: 'Proverbs 18:10',
      text:
          'The name of the LORD is a strong tower: the righteous runneth into it, and is safe.',
    ),
    (
      ref: '1 John 1:9',
      text:
          'If we confess our sins, he is faithful and just to forgive us our sins, and to cleanse us from all unrighteousness.',
    ),
    (
      ref: 'Mark 11:24',
      text:
          'Therefore I say unto you, What things soever ye desire, when ye pray, believe that ye receive them, and ye shall have them.',
    ),
    (
      ref: 'Proverbs 19:21',
      text:
          'There are many devices in a man’s heart; nevertheless the counsel of the LORD, that shall stand.',
    ),
    (
      ref: 'Mark 12:30-31',
      text:
          'And thou shalt love the Lord thy God with all thy heart, and with all thy soul, and with all thy mind, and with all thy strength: this is the first commandment. And the second is like, namely this, Thou shalt love thy neighbour as thyself. There is none other commandment greater than these.',
    ),
    (
      ref: 'Proverbs 21:23',
      text:
          'Whoso keepeth his mouth and his tongue keepeth his soul from troubles.',
    ),
    (
      ref: 'Luke 6:38',
      text:
          'Give, and it shall be given unto you; good measure, pressed down, and shaken together, and running over, shall men give into your bosom. For with the same measure that ye mete withal it shall be measured to you again.',
    ),
    (
      ref: 'Proverbs 22:1',
      text:
          'A good name is rather to be chosen than great riches, and loving favour rather than silver and gold.',
    ),
    (
      ref: 'Luke 12:32',
      text:
          'Fear not, little flock; for it is your Father’s good pleasure to give you the kingdom.',
    ),
    (
      ref: 'Proverbs 22:6',
      text:
          'Train up a child in the way he should go: and when he is old, he will not depart from it.',
    ),
    (
      ref: 'John 10:10',
      text:
          'The thief cometh not, but for to steal, and to kill, and to destroy: I am come that they might have life, and that they might have it more abundantly.',
    ),
    (
      ref: 'Proverbs 24:16',
      text:
          'For a just man falleth seven times, and riseth up again: but the wicked shall fall into mischief.',
    ),
    (
      ref: 'John 13:34',
      text:
          'A new commandment I give unto you, That ye love one another; as I have loved you, that ye also love one another.',
    ),
    (
      ref: 'Proverbs 25:28',
      text:
          'He that hath no rule over his own spirit is like a city that is broken down, and without walls.',
    ),
    (
      ref: 'John 14:27',
      text:
          'Peace I leave with you, my peace I give unto you: not as the world giveth, give I unto you. Let not your heart be troubled, neither let it be afraid.',
    ),
    (
      ref: 'Proverbs 27:17',
      text:
          'Iron sharpeneth iron; so a man sharpeneth the countenance of his friend.',
    ),
    (
      ref: 'John 15:5',
      text:
          'I am the vine, ye are the branches: He that abideth in me, and I in him, the same bringeth forth much fruit: for without me ye can do nothing.',
    ),
    (
      ref: 'Proverbs 28:13',
      text:
          'He that covereth his sins shall not prosper: but whoso confesseth and forsaketh them shall have mercy.',
    ),
    (
      ref: 'John 15:13',
      text:
          'Greater love hath no man than this, that a man lay down his life for his friends.',
    ),
    (
      ref: 'Proverbs 29:25',
      text:
          'The fear of man bringeth a snare: but whoso putteth his trust in the LORD shall be safe.',
    ),
    (
      ref: 'John 16:33',
      text:
          'These things I have spoken unto you, that in me ye might have peace. In the world ye shall have tribulation: but be of good cheer; I have overcome the world.',
    ),
    (
      ref: 'Revelation 3:20',
      text:
          'Behold, I stand at the door, and knock: if any man hear my voice, and open the door, I will come in to him, and will sup with him, and he with me.',
    ),
    (
      ref: '2 Corinthians 12:9',
      text:
          'And he said unto me, My grace is sufficient for thee: for my strength is made perfect in weakness. Most gladly therefore will I rather glory in my infirmities, that the power of Christ may rest upon me.',
    ),
    (
      ref: 'Matthew 4:4',
      text:
          'But he answered and said, It is written, Man shall not live by bread alone, but by every word that proceedeth out of the mouth of God.',
    ),
    (
      ref: 'Psalm 1:1',
      text:
          'Blessed is the man that walketh not in the counsel of the ungodly, nor standeth in the way of sinners, nor sitteth in the seat of the scornful.',
    ),
    (
      ref: 'Romans 1:16',
      text:
          'For I am not ashamed of the gospel of Christ: for it is the power of God unto salvation to every one that believeth; to the Jew first, and also to the Greek.',
    ),
    (
      ref: 'Proverbs 1:7',
      text:
          'The fear of the LORD is the beginning of knowledge: but fools despise wisdom and instruction.',
    ),
    (
      ref: 'Genesis 1:1',
      text: 'In the beginning God created the heaven and the earth.',
    ),
    (
      ref: 'Matthew 5:3',
      text:
          'Blessed are the poor in spirit: for theirs is the kingdom of heaven.',
    ),
    (
      ref: 'Psalm 4:8',
      text:
          'I will both lay me down in peace, and sleep: for thou, LORD, only makest me dwell in safety.',
    ),
    (
      ref: 'Romans 6:23',
      text:
          'For the wages of sin is death; but the gift of God is eternal life through Jesus Christ our Lord.',
    ),
    (
      ref: 'Proverbs 2:6',
      text:
          'For the LORD giveth wisdom: out of his mouth cometh knowledge and understanding.',
    ),
    (
      ref: 'Genesis 28:15',
      text:
          'And, behold, I am with thee, and will keep thee in all places whither thou goest, and will bring thee again into this land; for I will not leave thee, until I have done that which I have spoken to thee of.',
    ),
    (
      ref: 'Matthew 5:4',
      text: 'Blessed are they that mourn: for they shall be comforted.',
    ),
    (
      ref: 'Psalm 9:9-10',
      text:
          'The LORD also will be a refuge for the oppressed, a refuge in times of trouble. And they that know thy name will put their trust in thee: for thou, LORD, hast not forsaken them that seek thee.',
    ),
    (
      ref: 'Romans 8:1',
      text:
          'There is therefore now no condemnation to them which are in Christ Jesus, who walk not after the flesh, but after the Spirit.',
    ),
    (
      ref: 'Proverbs 3:9-10',
      text:
          'Honour the LORD with thy substance, and with the firstfruits of all thine increase: So shall thy barns be filled with plenty, and thy presses shall burst out with new wine.',
    ),
    (
      ref: 'Genesis 50:20',
      text:
          'But as for you, ye thought evil against me; but God meant it unto good, to bring to pass, as it is this day, to save much people alive.',
    ),
    (
      ref: 'Matthew 5:5',
      text: 'Blessed are the meek: for they shall inherit the earth.',
    ),
    (
      ref: 'Psalm 16:8',
      text:
          'I have set the LORD always before me: because he is at my right hand, I shall not be moved.',
    ),
    (
      ref: 'Romans 8:31',
      text:
          'What shall we then say to these things? If God be for us, who can be against us?',
    ),
    (
      ref: 'Proverbs 3:27',
      text:
          'Withhold not good from them to whom it is due, when it is in the power of thine hand to do it.',
    ),
    (
      ref: 'Exodus 15:2',
      text:
          'The LORD is my strength and song, and he is become my salvation: he is my God, and I will prepare him an habitation; my father’s God, and I will exalt him.',
    ),
    (
      ref: 'Matthew 5:7',
      text: 'Blessed are the merciful: for they shall obtain mercy.',
    ),
    (
      ref: 'Psalm 16:11',
      text:
          'Thou wilt shew me the path of life: in thy presence is fulness of joy; at thy right hand there are pleasures for evermore.',
    ),
    (
      ref: 'Romans 10:17',
      text: 'So then faith cometh by hearing, and hearing by the word of God.',
    ),
    (
      ref: 'Proverbs 6:6-8',
      text:
          'Go to the ant, thou sluggard; consider her ways, and be wise: Which having no guide, overseer, or ruler, Provideth her meat in the summer, and gathereth her food in the harvest.',
    ),
    (
      ref: 'Exodus 33:14',
      text:
          'And he said, My presence shall go with thee, and I will give thee rest.',
    ),
    (
      ref: 'Matthew 5:44-45',
      text:
          'But I say unto you, Love your enemies, bless them that curse you, do good to them that hate you, and pray for them which despitefully use you, and persecute you; That ye may be the children of your Father which is in heaven: for he maketh his sun to rise on the evil and on the good, and sendeth rain on the just and on the unjust.',
    ),
    (
      ref: 'Psalm 18:2',
      text:
          'The LORD is my rock, and my fortress, and my deliverer; my God, my strength, in whom I will trust; my buckler, and the horn of my salvation, and my high tower.',
    ),
    (
      ref: 'Romans 12:21',
      text: 'Be not overcome of evil, but overcome evil with good.',
    ),
    (
      ref: 'Proverbs 10:9',
      text:
          'He that walketh uprightly walketh surely: but he that perverteth his ways shall be known.',
    ),
    (
      ref: 'Deuteronomy 31:8',
      text:
          'And the LORD, he it is that doth go before thee; he will be with thee, he will not fail thee, neither forsake thee: fear not, neither be dismayed.',
    ),
    (
      ref: 'Matthew 6:6',
      text:
          'But thou, when thou prayest, enter into thy closet, and when thou hast shut thy door, pray to thy Father which is in secret; and thy Father which seeth in secret shall reward thee openly.',
    ),
    (
      ref: 'Psalm 19:1',
      text:
          'The heavens declare the glory of God; and the firmament sheweth his handywork.',
    ),
    (
      ref: '1 Corinthians 2:9',
      text:
          'But as it is written, Eye hath not seen, nor ear heard, neither have entered into the heart of man, the things which God hath prepared for them that love him.',
    ),
    (
      ref: 'Proverbs 10:19',
      text:
          'In the multitude of words there wanteth not sin: but he that refraineth his lips is wise.',
    ),
    (
      ref: 'Joshua 24:15',
      text:
          'And if it seem evil unto you to serve the LORD, choose you this day whom ye will serve; whether the gods which your fathers served that were on the other side of the flood, or the gods of the Amorites, in whose land ye dwell: but as for me and my house, we will serve the LORD.',
    ),
    (
      ref: 'Matthew 6:19-21',
      text:
          'Lay not up for yourselves treasures upon earth, where moth and rust doth corrupt, and where thieves break through and steal: But lay up for yourselves treasures in heaven, where neither moth nor rust doth corrupt, and where thieves do not break through nor steal: For where your treasure is, there will your heart be also.',
    ),
    (
      ref: 'Psalm 25:4-5',
      text:
          'Shew me thy ways, O LORD; teach me thy paths. Lead me in thy truth, and teach me: for thou art the God of my salvation; on thee do I wait all the day.',
    ),
    (
      ref: '1 Corinthians 13:13',
      text:
          'And now abideth faith, hope, charity, these three; but the greatest of these is charity.',
    ),
    (
      ref: 'Proverbs 14:23',
      text:
          'In all labour there is profit: but the talk of the lips tendeth only to penury.',
    ),
    (
      ref: '1 Samuel 16:7',
      text:
          'But the LORD said unto Samuel, Look not on his countenance, or on the height of his stature; because I have refused him: for the Lord seeth not as man seeth; for man looketh on the outward appearance, but the LORD looketh on the heart.',
    ),
    (
      ref: 'Matthew 6:26',
      text:
          'Behold the fowls of the air: for they sow not, neither do they reap, nor gather into barns; yet your heavenly Father feedeth them. Are ye not much better than they?',
    ),
    (
      ref: 'Psalm 28:7',
      text:
          'The LORD is my strength and my shield; my heart trusted in him, and I am helped: therefore my heart greatly rejoiceth; and with my song will I praise him.',
    ),
    (
      ref: '1 Corinthians 15:57-58',
      text:
          'But thanks be to God, which giveth us the victory through our Lord Jesus Christ. Therefore, my beloved brethren, be ye stedfast, unmoveable, always abounding in the work of the Lord, forasmuch as ye know that your labour is not in vain in the Lord.',
    ),
    (
      ref: 'Proverbs 16:18',
      text:
          'Pride goeth before destruction, and an haughty spirit before a fall.',
    ),
    (
      ref: '2 Samuel 22:31',
      text:
          'As for God, his way is perfect; the word of the LORD is tried: he is a buckler to all them that trust in him.',
    ),
    (
      ref: 'Matthew 7:24-25',
      text:
          'Therefore whosoever heareth these sayings of mine, and doeth them, I will liken him unto a wise man, which built his house upon a rock: And the rain descended, and the floods came, and the winds blew, and beat upon that house; and it fell not: for it was founded upon a rock.',
    ),
    (
      ref: 'Psalm 32:8',
      text:
          'I will instruct thee and teach thee in the way which thou shalt go: I will guide thee with mine eye.',
    ),
    (
      ref: '2 Corinthians 4:16-18',
      text:
          'For which cause we faint not; but though our outward man perish, yet the inward man is renewed day by day. For our light affliction, which is but for a moment, worketh for us a far more exceeding and eternal weight of glory; While we look not at the things which are seen, but at the things which are not seen: for the things which are seen are temporal; but the things which are not seen are eternal.',
    ),
    (
      ref: 'Proverbs 16:24',
      text:
          'Pleasant words are as an honeycomb, sweet to the soul, and health to the bones.',
    ),
    (
      ref: '1 Chronicles 16:11',
      text: 'Seek the LORD and his strength, seek his face continually.',
    ),
    (
      ref: 'Matthew 10:29-31',
      text:
          'Are not two sparrows sold for a farthing? and one of them shall not fall on the ground without your Father. But the very hairs of your head are all numbered. Fear ye not therefore, ye are of more value than many sparrows.',
    ),
    (
      ref: 'Psalm 34:8',
      text:
          'O taste and see that the LORD is good: blessed is the man that trusteth in him.',
    ),
    (
      ref: '2 Corinthians 9:7',
      text:
          'Every man according as he purposeth in his heart, so let him give; not grudgingly, or of necessity: for God loveth a cheerful giver.',
    ),
    (
      ref: 'Proverbs 17:17',
      text:
          'A friend loveth at all times, and a brother is born for adversity.',
    ),
    (
      ref: '2 Chronicles 7:14',
      text:
          'If my people, which are called by my name, shall humble themselves, and pray, and seek my face, and turn from their wicked ways; then will I hear from heaven, and will forgive their sin, and will heal their land.',
    ),
    (
      ref: 'Matthew 16:24',
      text:
          'Then said Jesus unto his disciples, If any man will come after me, let him deny himself, and take up his cross, and follow me.',
    ),
    (
      ref: 'Psalm 37:23-24',
      text:
          'The steps of a good man are ordered by the LORD: and he delighteth in his way. Though he fall, he shall not be utterly cast down: for the LORD upholdeth him with his hand.',
    ),
    (
      ref: 'Galatians 2:20',
      text:
          'I am crucified with Christ: nevertheless I live; yet not I, but Christ liveth in me: and the life which I now live in the flesh I live by the faith of the Son of God, who loved me, and gave himself for me.',
    ),
    (
      ref: 'Proverbs 18:24',
      text:
          'A man that hath friends must shew himself friendly: and there is a friend that sticketh closer than a brother.',
    ),
    (
      ref: 'Nehemiah 8:10',
      text:
          'Then he said unto them, Go your way, eat the fat, and drink the sweet, and send portions unto them for whom nothing is prepared: for this day is holy unto our Lord: neither be ye sorry; for the joy of the LORD is your strength.',
    ),
    (
      ref: 'Matthew 28:19-20',
      text:
          'Go ye therefore, and teach all nations, baptizing them in the name of the Father, and of the Son, and of the Holy Ghost: Teaching them to observe all things whatsoever I have commanded you: and, lo, I am with you alway, even unto the end of the world. Amen.',
    ),
    (
      ref: 'Psalm 42:11',
      text:
          'Why art thou cast down, O my soul? and why art thou disquieted within me? hope thou in God: for I shall yet praise him, who is the health of my countenance, and my God.',
    ),
    (
      ref: 'Galatians 5:1',
      text:
          'Stand fast therefore in the liberty wherewith Christ hath made us free, and be not entangled again with the yoke of bondage.',
    ),
    (
      ref: 'Proverbs 19:11',
      text:
          'The discretion of a man deferreth his anger; and it is his glory to pass over a transgression.',
    ),
    (
      ref: 'Job 23:10',
      text:
          'But he knoweth the way that I take: when he hath tried me, I shall come forth as gold.',
    ),
    (
      ref: 'Mark 8:36',
      text:
          'For what shall it profit a man, if he shall gain the whole world, and lose his own soul?',
    ),
    (
      ref: 'Psalm 46:10',
      text:
          'Be still, and know that I am God: I will be exalted among the heathen, I will be exalted in the earth.',
    ),
    (
      ref: 'Ephesians 3:20-21',
      text:
          'Now unto him that is able to do exceeding abundantly above all that we ask or think, according to the power that worketh in us, Unto him be glory in the church by Christ Jesus throughout all ages, world without end. Amen.',
    ),
    (
      ref: 'Proverbs 20:22',
      text:
          'Say not thou, I will recompense evil; but wait on the LORD, and he shall save thee.',
    ),
    (
      ref: 'Isaiah 9:6',
      text:
          'For unto us a child is born, unto us a son is given: and the government shall be upon his shoulder: and his name shall be called Wonderful, Counsellor, The mighty God, The everlasting Father, The Prince of Peace.',
    ),
    (
      ref: 'Mark 9:23',
      text:
          'Jesus said unto him, If thou canst believe, all things are possible to him that believeth.',
    ),
    (
      ref: 'Psalm 62:1-2',
      text:
          'Truly my soul waiteth upon God: from him cometh my salvation. He only is my rock and my salvation; he is my defence; I shall not be greatly moved.',
    ),
    (
      ref: 'Ephesians 4:29',
      text:
          'Let no corrupt communication proceed out of your mouth, but that which is good to the use of edifying, that it may minister grace unto the hearers.',
    ),
    (
      ref: 'Proverbs 27:1',
      text:
          'Boast not thyself of to morrow; for thou knowest not what a day may bring forth.',
    ),
    (
      ref: 'Isaiah 12:2',
      text:
          'Behold, God is my salvation; I will trust, and not be afraid: for the LORD JEHOVAH is my strength and my song; he also is become my salvation.',
    ),
    (
      ref: 'Mark 11:25',
      text:
          'And when ye stand praying, forgive, if ye have ought against any: that your Father also which is in heaven may forgive you your trespasses.',
    ),
    (
      ref: 'Psalm 73:26',
      text:
          'My flesh and my heart faileth: but God is the strength of my heart, and my portion for ever.',
    ),
    (
      ref: 'Ephesians 6:10-11',
      text:
          'Finally, my brethren, be strong in the Lord, and in the power of his might. Put on the whole armour of God, that ye may be able to stand against the wiles of the devil.',
    ),
    (
      ref: 'Isaiah 30:21',
      text:
          'And thine ears shall hear a word behind thee, saying, This is the way, walk ye in it, when ye turn to the right hand, and when ye turn to the left.',
    ),
    (
      ref: 'Luke 19:10',
      text:
          'For the Son of man is come to seek and to save that which was lost.',
    ),
    (
      ref: 'Psalm 84:11',
      text:
          'For the LORD God is a sun and shield: the LORD will give grace and glory: no good thing will he withhold from them that walk uprightly.',
    ),
    (
      ref: 'Philippians 1:6',
      text:
          'Being confident of this very thing, that he which hath begun a good work in you will perform it until the day of Jesus Christ:',
    ),
    (
      ref: 'Isaiah 40:8',
      text:
          'The grass withereth, the flower fadeth: but the word of our God shall stand for ever.',
    ),
    (
      ref: 'John 4:13-14',
      text:
          'Jesus answered and said unto her, Whosoever drinketh of this water shall thirst again: But whosoever drinketh of the water that I shall give him shall never thirst; but the water that I shall give him shall be in him a well of water springing up into everlasting life.',
    ),
    (
      ref: 'Psalm 86:5',
      text:
          'For thou, Lord, art good, and ready to forgive; and plenteous in mercy unto all them that call upon thee.',
    ),
    (
      ref: 'Philippians 3:13-14',
      text:
          'Brethren, I count not myself to have apprehended: but this one thing I do, forgetting those things which are behind, and reaching forth unto those things which are before, I press toward the mark for the prize of the high calling of God in Christ Jesus.',
    ),
    (
      ref: 'Isaiah 40:29',
      text:
          'He giveth power to the faint; and to them that have no might he increaseth strength.',
    ),
    (
      ref: 'John 5:24',
      text:
          'Verily, verily, I say unto you, He that heareth my word, and believeth on him that sent me, hath everlasting life, and shall not come into condemnation; but is passed from death unto life.',
    ),
    (
      ref: 'Psalm 90:12',
      text:
          'So teach us to number our days, that we may apply our hearts unto wisdom.',
    ),
    (
      ref: 'Philippians 4:19',
      text:
          'But my God shall supply all your need according to his riches in glory by Christ Jesus.',
    ),
    (
      ref: 'Isaiah 53:5',
      text:
          'But he was wounded for our transgressions, he was bruised for our iniquities: the chastisement of our peace was upon him; and with his stripes we are healed.',
    ),
    (
      ref: 'John 6:35',
      text:
          'And Jesus said unto them, I am the bread of life: he that cometh to me shall never hunger; and he that believeth on me shall never thirst.',
    ),
    (
      ref: 'Psalm 94:19',
      text:
          'In the multitude of my thoughts within me thy comforts delight my soul.',
    ),
    (
      ref: 'Colossians 3:15',
      text:
          'And let the peace of God rule in your hearts, to the which also ye are called in one body; and be ye thankful.',
    ),
    (
      ref: 'Isaiah 54:10',
      text:
          'For the mountains shall depart, and the hills be removed; but my kindness shall not depart from thee, neither shall the covenant of my peace be removed, saith the LORD that hath mercy on thee.',
    ),
    (
      ref: 'John 8:12',
      text:
          'Then spake Jesus again unto them, saying, I am the light of the world: he that followeth me shall not walk in darkness, but shall have the light of life.',
    ),
    (
      ref: 'Psalm 100:4-5',
      text:
          'Enter into his gates with thanksgiving, and into his courts with praise: be thankful unto him, and bless his name. For the LORD is good; his mercy is everlasting; and his truth endureth to all generations.',
    ),
    (
      ref: '2 Timothy 2:15',
      text:
          'Study to shew thyself approved unto God, a workman that needeth not to be ashamed, rightly dividing the word of truth.',
    ),
    (
      ref: 'Isaiah 55:8-9',
      text:
          'For my thoughts are not your thoughts, neither are your ways my ways, saith the LORD. For as the heavens are higher than the earth, so are my ways higher than your ways, and my thoughts than your thoughts.',
    ),
    (
      ref: 'John 8:31-32',
      text:
          'Then said Jesus to those Jews which believed on him, If ye continue in my word, then are ye my disciples indeed; And ye shall know the truth, and the truth shall make you free.',
    ),
    (
      ref: 'Psalm 103:12',
      text:
          'As far as the east is from the west, so far hath he removed our transgressions from us.',
    ),
    (
      ref: '2 Timothy 3:16-17',
      text:
          'All scripture is given by inspiration of God, and is profitable for doctrine, for reproof, for correction, for instruction in righteousness: That the man of God may be perfect, throughly furnished unto all good works.',
    ),
    (
      ref: 'Jeremiah 17:7',
      text:
          'Blessed is the man that trusteth in the LORD, and whose hope the LORD is.',
    ),
    (
      ref: 'John 8:36',
      text:
          'If the Son therefore shall make you free, ye shall be free indeed.',
    ),
    (
      ref: 'Psalm 107:1',
      text:
          'O give thanks unto the LORD, for he is good: for his mercy endureth for ever.',
    ),
    (
      ref: 'Hebrews 12:1-2',
      text:
          'Wherefore seeing we also are compassed about with so great a cloud of witnesses, let us lay aside every weight, and the sin which doth so easily beset us, and let us run with patience the race that is set before us, Looking unto Jesus the author and finisher of our faith; who for the joy that was set before him endured the cross, despising the shame, and is set down at the right hand of the throne of God.',
    ),
    (
      ref: 'Jeremiah 32:27',
      text:
          'Behold, I am the LORD, the God of all flesh: is there any thing too hard for me?',
    ),
    (
      ref: 'John 10:11',
      text:
          'I am the good shepherd: the good shepherd giveth his life for the sheep.',
    ),
    (
      ref: 'Psalm 112:7',
      text:
          'He shall not be afraid of evil tidings: his heart is fixed, trusting in the LORD.',
    ),
    (
      ref: 'Hebrews 13:8',
      text: 'Jesus Christ the same yesterday, and to day, and for ever.',
    ),
    (
      ref: 'Jeremiah 33:3',
      text:
          'Call unto me, and I will answer thee, and shew thee great and mighty things, which thou knowest not.',
    ),
    (
      ref: 'John 10:27-28',
      text:
          'My sheep hear my voice, and I know them, and they follow me: And I give unto them eternal life; and they shall never perish, neither shall any man pluck them out of my hand.',
    ),
    (
      ref: 'Psalm 119:11',
      text:
          'Thy word have I hid in mine heart, that I might not sin against thee.',
    ),
    (
      ref: 'James 1:2-3',
      text:
          'My brethren, count it all joy when ye fall into divers temptations; Knowing this, that the trying of your faith worketh patience.',
    ),
    (
      ref: 'Ezekiel 36:26',
      text:
          'A new heart also will I give you, and a new spirit will I put within you: and I will take away the stony heart out of your flesh, and I will give you an heart of flesh.',
    ),
    (
      ref: 'John 11:25-26',
      text:
          'Jesus said unto her, I am the resurrection, and the life: he that believeth in me, though he were dead, yet shall he live: And whosoever liveth and believeth in me shall never die. Believest thou this?',
    ),
    (
      ref: 'Psalm 121:7-8',
      text:
          'The LORD shall preserve thee from all evil: he shall preserve thy soul. The LORD shall preserve thy going out and thy coming in from this time forth, and even for evermore.',
    ),
    (
      ref: 'James 1:17',
      text:
          'Every good gift and every perfect gift is from above, and cometh down from the Father of lights, with whom is no variableness, neither shadow of turning.',
    ),
    (
      ref: 'John 14:1',
      text:
          'Let not your heart be troubled: ye believe in God, believe also in me.',
    ),
    (ref: 'Psalm 126:5', text: 'They that sow in tears shall reap in joy.'),
    (
      ref: 'James 1:22',
      text:
          'But be ye doers of the word, and not hearers only, deceiving your own selves.',
    ),
    (
      ref: 'John 14:6',
      text:
          'Jesus saith unto him, I am the way, the truth, and the life: no man cometh unto the Father, but by me.',
    ),
    (
      ref: 'Psalm 130:5',
      text:
          'I wait for the LORD, my soul doth wait, and in his word do I hope.',
    ),
    (
      ref: 'James 4:10',
      text:
          'Humble yourselves in the sight of the Lord, and he shall lift you up.',
    ),
    (
      ref: 'John 15:11',
      text:
          'These things have I spoken unto you, that my joy might remain in you, and that your joy might be full.',
    ),
    (
      ref: 'Psalm 138:8',
      text:
          'The LORD will perfect that which concerneth me: thy mercy, O LORD, endureth for ever: forsake not the works of thine own hands.',
    ),
    (
      ref: '1 Peter 4:8',
      text:
          'And above all things have fervent charity among yourselves: for charity shall cover the multitude of sins.',
    ),
    (
      ref: 'John 20:29',
      text:
          'Jesus saith unto him, Thomas, because thou hast seen me, thou hast believed: blessed are they that have not seen, and yet have believed.',
    ),
    (
      ref: 'Psalm 145:8-9',
      text:
          'The LORD is gracious, and full of compassion; slow to anger, and of great mercy. The LORD is good to all: and his tender mercies are over all his works.',
    ),
    (
      ref: '1 John 4:4',
      text:
          'Ye are of God, little children, and have overcome them: because greater is he that is in you, than he that is in the world.',
    ),
    (
      ref: '1 John 4:18',
      text:
          'There is no fear in love; but perfect love casteth out fear: because fear hath torment. He that feareth is not made perfect in love.',
    ),
    (
      ref: 'Revelation 21:4',
      text:
          'And God shall wipe away all tears from their eyes; and there shall be no more death, neither sorrow, nor crying, neither shall there be any more pain: for the former things are passed away.',
    ),
    (
      ref: 'Matthew 5:10',
      text:
          'Blessed are they which are persecuted for righteousness’ sake: for theirs is the kingdom of heaven.',
    ),
    (
      ref: 'Psalm 3:3',
      text:
          'But thou, O LORD, art a shield for me; my glory, and the lifter up of mine head.',
    ),
    (ref: 'Luke 1:37', text: 'For with God nothing shall be impossible.'),
    (
      ref: 'Proverbs 3:1-2',
      text:
          'My son, forget not my law; but let thine heart keep my commandments: For length of days, and long life, and peace, shall they add to thee.',
    ),
    (
      ref: 'Genesis 1:27',
      text:
          'So God created man in his own image, in the image of God created he him; male and female created he them.',
    ),
    (
      ref: 'Matthew 6:3-4',
      text:
          'But when thou doest alms, let not thy left hand know what thy right hand doeth: That thine alms may be in secret: and thy Father which seeth in secret himself shall reward thee openly.',
    ),
    (
      ref: 'Psalm 5:12',
      text:
          'For thou, LORD, wilt bless the righteous; with favour wilt thou compass him as with a shield.',
    ),
    (
      ref: 'Acts 4:12',
      text:
          'Neither is there salvation in any other: for there is none other name under heaven given among men, whereby we must be saved.',
    ),
    (
      ref: 'Proverbs 4:18',
      text:
          'But the path of the just is as the shining light, that shineth more and more unto the perfect day.',
    ),
    (
      ref: 'Genesis 9:13',
      text:
          'I do set my bow in the cloud, and it shall be for a token of a covenant between me and the earth.',
    ),
    (
      ref: 'Matthew 7:1-2',
      text:
          'Judge not, that ye be not judged. For with what judgment ye judge, ye shall be judged: and with what measure ye mete, it shall be measured to you again.',
    ),
    (
      ref: 'Psalm 8:3-4',
      text:
          'When I consider thy heavens, the work of thy fingers, the moon and the stars, which thou hast ordained; What is man, that thou art mindful of him? and the son of man, that thou visitest him?',
    ),
    (
      ref: 'Acts 16:31',
      text:
          'And they said, Believe on the Lord Jesus Christ, and thou shalt be saved, and thy house.',
    ),
    (
      ref: 'Proverbs 4:25-27',
      text:
          'Let thine eyes look right on, and let thine eyelids look straight before thee. Ponder the path of thy feet, and let all thy ways be established. Turn not to the right hand nor to the left: remove thy foot from evil.',
    ),
    (
      ref: 'Exodus 20:12',
      text:
          'Honour thy father and thy mother: that thy days may be long upon the land which the LORD thy God giveth thee.',
    ),
    (
      ref: 'Matthew 7:13-14',
      text:
          'Enter ye in at the strait gate: for wide is the gate, and broad is the way, that leadeth to destruction, and many there be which go in thereat: Because strait is the gate, and narrow is the way, which leadeth unto life, and few there be that find it.',
    ),
    (
      ref: 'Psalm 20:7',
      text:
          'Some trust in chariots, and some in horses: but we will remember the name of the LORD our God.',
    ),
    (
      ref: 'Romans 5:3-5',
      text:
          'And not only so, but we glory in tribulations also: knowing that tribulation worketh patience; And patience, experience; and experience, hope: And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the Holy Ghost which is given unto us.',
    ),
    (
      ref: 'Proverbs 9:10',
      text:
          'The fear of the LORD is the beginning of wisdom: and the knowledge of the holy is understanding.',
    ),
    (
      ref: 'Leviticus 19:18',
      text:
          'Thou shalt not avenge, nor bear any grudge against the children of thy people, but thou shalt love thy neighbour as thyself: I am the LORD.',
    ),
    (
      ref: 'Matthew 9:37-38',
      text:
          'Then saith he unto his disciples, The harvest truly is plenteous, but the labourers are few; Pray ye therefore the Lord of the harvest, that he will send forth labourers into his harvest.',
    ),
    (
      ref: 'Psalm 23:4',
      text:
          'Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me.',
    ),
    (
      ref: 'Romans 8:18',
      text:
          'For I reckon that the sufferings of this present time are not worthy to be compared with the glory which shall be revealed in us.',
    ),
    (
      ref: 'Proverbs 10:22',
      text:
          'The blessing of the LORD, it maketh rich, and he addeth no sorrow with it.',
    ),
    (
      ref: 'Numbers 23:19',
      text:
          'God is not a man, that he should lie; neither the son of man, that he should repent: hath he said, and shall he not do it? or hath he spoken, and shall he not make it good?',
    ),
    (
      ref: 'Matthew 11:29-30',
      text:
          'Take my yoke upon you, and learn of me; for I am meek and lowly in heart: and ye shall find rest unto your souls. For my yoke is easy, and my burden is light.',
    ),
    (
      ref: 'Psalm 24:1',
      text:
          'The earth is the LORD’s, and the fulness thereof; the world, and they that dwell therein.',
    ),
    (
      ref: 'Romans 8:26',
      text:
          'Likewise the Spirit also helpeth our infirmities: for we know not what we should pray for as we ought: but the Spirit itself maketh intercession for us with groanings which cannot be uttered.',
    ),
    (
      ref: 'Proverbs 13:12',
      text:
          'Hope deferred maketh the heart sick: but when the desire cometh, it is a tree of life.',
    ),
    (
      ref: 'Jeremiah 29:13',
      text:
          'And ye shall seek me, and find me, when ye shall search for me with all your heart.',
    ),
    (
      ref: 'Matthew 25:40',
      text:
          'And the King shall answer and say unto them, Verily I say unto you, Inasmuch as ye have done it unto one of the least of these my brethren, ye have done it unto me.',
    ),
    (
      ref: 'Psalm 27:14',
      text:
          'Wait on the LORD: be of good courage, and he shall strengthen thine heart: wait, I say, on the LORD.',
    ),
    (
      ref: 'Romans 10:13',
      text:
          'For whosoever shall call upon the name of the Lord shall be saved.',
    ),
    (
      ref: 'Proverbs 16:7',
      text:
          'When a man’s ways please the LORD, he maketh even his enemies to be at peace with him.',
    ),
    (
      ref: 'Deuteronomy 6:6-7',
      text:
          'And these words, which I command thee this day, shall be in thine heart: And thou shalt teach them diligently unto thy children, and shalt talk of them when thou sittest in thine house, and when thou walkest by the way, and when thou liest down, and when thou risest up.',
    ),
    (
      ref: 'Mark 1:17',
      text:
          'And Jesus said unto them, Come ye after me, and I will make you to become fishers of men.',
    ),
    (
      ref: 'Psalm 29:11',
      text:
          'The LORD will give strength unto his people; the LORD will bless his people with peace.',
    ),
    (
      ref: 'Romans 12:18',
      text:
          'If it be possible, as much as lieth in you, live peaceably with all men.',
    ),
    (
      ref: 'Proverbs 16:32',
      text:
          'He that is slow to anger is better than the mighty; and he that ruleth his spirit than he that taketh a city.',
    ),
    (
      ref: 'Joshua 1:8',
      text:
          'This book of the law shall not depart out of thy mouth; but thou shalt meditate therein day and night, that thou mayest observe to do according to all that is written therein: for then thou shalt make thy way prosperous, and then thou shalt have good success.',
    ),
    (
      ref: 'Mark 10:15',
      text:
          'Verily I say unto you, Whosoever shall not receive the kingdom of God as a little child, he shall not enter therein.',
    ),
    (
      ref: 'Psalm 104:33-34',
      text:
          'I will sing unto the LORD as long as I live: I will sing praise to my God while I have my being. My meditation of him shall be sweet: I will be glad in the LORD.',
    ),
    (
      ref: 'Romans 15:4',
      text:
          'For whatsoever things were written aforetime were written for our learning, that we through patience and comfort of the scriptures might have hope.',
    ),
    (
      ref: 'Proverbs 18:21',
      text:
          'Death and life are in the power of the tongue: and they that love it shall eat the fruit thereof.',
    ),
    (
      ref: '1 Kings 8:56',
      text:
          'Blessed be the LORD, that hath given rest unto his people Israel, according to all that he promised: there hath not failed one word of all his good promise, which he promised by the hand of Moses his servant.',
    ),
    (
      ref: 'Mark 10:45',
      text:
          'For even the Son of man came not to be ministered unto, but to minister, and to give his life a ransom for many.',
    ),
    (
      ref: 'Psalm 34:19',
      text:
          'Many are the afflictions of the righteous: but the LORD delivereth him out of them all.',
    ),
    (
      ref: '1 Corinthians 3:16',
      text:
          'Know ye not that ye are the temple of God, and that the Spirit of God dwelleth in you?',
    ),
    (
      ref: 'Proverbs 19:17',
      text:
          'He that hath pity upon the poor lendeth unto the LORD; and that which he hath given will he pay him again.',
    ),
    (
      ref: '1 Samuel 2:2',
      text:
          'There is none holy as the LORD: for there is none beside thee: neither is there any rock like our God.',
    ),
    (
      ref: 'Luke 6:36',
      text: 'Be ye therefore merciful, as your Father also is merciful.',
    ),
    (
      ref: 'Psalm 36:7',
      text:
          'How excellent is thy lovingkindness, O God! therefore the children of men put their trust under the shadow of thy wings.',
    ),
    (
      ref: '2 Corinthians 1:3-4',
      text:
          'Blessed be God, even the Father of our Lord Jesus Christ, the Father of mercies, and the God of all comfort; Who comforteth us in all our tribulation, that we may be able to comfort them which are in any trouble, by the comfort wherewith we ourselves are comforted of God.',
    ),
    (
      ref: 'Proverbs 22:4',
      text:
          'By humility and the fear of the LORD are riches, and honour, and life.',
    ),
    (
      ref: '1 Chronicles 29:11',
      text:
          'Thine, O LORD, is the greatness, and the power, and the glory, and the victory, and the majesty: for all that is in the heaven and in the earth is thine; thine is the kingdom, O LORD, and thou art exalted as head above all.',
    ),
    (
      ref: 'Luke 6:45',
      text:
          'A good man out of the good treasure of his heart bringeth forth that which is good; and an evil man out of the evil treasure of his heart bringeth forth that which is evil: for of the abundance of the heart his mouth speaketh.',
    ),
    (
      ref: 'Psalm 37:5',
      text:
          'Commit thy way unto the LORD; trust also in him; and he shall bring it to pass.',
    ),
    (
      ref: '2 Corinthians 3:17',
      text:
          'Now the Lord is that Spirit: and where the Spirit of the Lord is, there is liberty.',
    ),
    (
      ref: 'Proverbs 24:3-4',
      text:
          'Through wisdom is an house builded; and by understanding it is established: And by knowledge shall the chambers be filled with all precious and pleasant riches.',
    ),
    (
      ref: 'Job 42:2',
      text:
          'I know that thou canst do every thing, and that no thought can be withholden from thee.',
    ),
    (
      ref: 'Matthew 24:35',
      text:
          'Heaven and earth shall pass away, but my words shall not pass away.',
    ),
    (
      ref: 'Psalm 40:1-2',
      text:
          'I waited patiently for the LORD; and he inclined unto me, and heard my cry. He brought me up also out of an horrible pit, out of the miry clay, and set my feet upon a rock, and established my goings.',
    ),
    (
      ref: 'Galatians 6:2',
      text: 'Bear ye one another’s burdens, and so fulfil the law of Christ.',
    ),
    (
      ref: 'Proverbs 25:11',
      text: 'A word fitly spoken is like apples of gold in pictures of silver.',
    ),
    (
      ref: 'Isaiah 1:18',
      text:
          'Come now, and let us reason together, saith the LORD: though your sins be as scarlet, they shall be as white as snow; though they be red like crimson, they shall be as wool.',
    ),
    (
      ref: 'Luke 15:10',
      text:
          'Likewise, I say unto you, there is joy in the presence of the angels of God over one sinner that repenteth.',
    ),
    (
      ref: 'Psalm 48:14',
      text:
          'For this God is our God for ever and ever: he will be our guide even unto death.',
    ),
    (
      ref: 'Ephesians 2:10',
      text:
          'For we are his workmanship, created in Christ Jesus unto good works, which God hath before ordained that we should walk in them.',
    ),
    (
      ref: 'Proverbs 28:1',
      text:
          'The wicked flee when no man pursueth: but the righteous are bold as a lion.',
    ),
    (
      ref: 'Isaiah 25:1',
      text:
          'O LORD, thou art my God; I will exalt thee, I will praise thy name; for thou hast done wonderful things; thy counsels of old are faithfulness and truth.',
    ),
    (
      ref: 'John 3:3',
      text:
          'Jesus answered and said unto him, Verily, verily, I say unto thee, Except a man be born again, he cannot see the kingdom of God.',
    ),
    (
      ref: 'Psalm 61:2',
      text:
          'From the end of the earth will I cry unto thee, when my heart is overwhelmed: lead me to the rock that is higher than I.',
    ),
    (
      ref: 'Ephesians 5:1-2',
      text:
          'Be ye therefore followers of God, as dear children; And walk in love, as Christ also hath loved us, and hath given himself for us an offering and a sacrifice to God for a sweetsmelling savour.',
    ),
    (
      ref: 'Proverbs 30:5',
      text:
          'Every word of God is pure: he is a shield unto them that put their trust in him.',
    ),
    (
      ref: 'Isaiah 32:17',
      text:
          'And the work of righteousness shall be peace; and the effect of righteousness quietness and assurance for ever.',
    ),
    (
      ref: 'John 3:17',
      text:
          'For God sent not his Son into the world to condemn the world; but that the world through him might be saved.',
    ),
    (
      ref: 'Psalm 63:1',
      text:
          'O God, thou art my God; early will I seek thee: my soul thirsteth for thee, my flesh longeth for thee in a dry and thirsty land, where no water is;',
    ),
    (
      ref: 'Philippians 1:21',
      text: 'For to me to live is Christ, and to die is gain.',
    ),
    (
      ref: 'Isaiah 46:4',
      text:
          'And even to your old age I am he; and even to hoar hairs will I carry you: I have made, and I will bear; even I will carry, and will deliver you.',
    ),
    (
      ref: 'John 6:37',
      text:
          'All that the Father giveth me shall come to me; and him that cometh to me I will in no wise cast out.',
    ),
    (
      ref: 'Psalm 89:1',
      text:
          'I will sing of the mercies of the LORD for ever: with my mouth will I make known thy faithfulness to all generations.',
    ),
    (
      ref: 'Philippians 4:4',
      text: 'Rejoice in the Lord alway: and again I say, Rejoice.',
    ),
    (
      ref: 'Isaiah 52:7',
      text:
          'How beautiful upon the mountains are the feet of him that bringeth good tidings, that publisheth peace; that bringeth good tidings of good, that publisheth salvation; that saith unto Zion, Thy God reigneth!',
    ),
    (
      ref: 'John 6:63',
      text:
          'It is the spirit that quickeneth; the flesh profiteth nothing: the words that I speak unto you, they are spirit, and they are life.',
    ),
    (
      ref: 'Psalm 103:1',
      text:
          'Bless the LORD, O my soul: and all that is within me, bless his holy name.',
    ),
    (
      ref: 'Colossians 2:6-7',
      text:
          'As ye have therefore received Christ Jesus the Lord, so walk ye in him: Rooted and built up in him, and stablished in the faith, as ye have been taught, abounding therein with thanksgiving.',
    ),
    (
      ref: 'Isaiah 58:11',
      text:
          'And the LORD shall guide thee continually, and satisfy thy soul in drought, and make fat thy bones: and thou shalt be like a watered garden, and like a spring of water, whose waters fail not.',
    ),
    (
      ref: 'John 12:26',
      text:
          'If any man serve me, let him follow me; and where I am, there shall also my servant be: if any man serve me, him will my Father honour.',
    ),
    (
      ref: 'Psalm 113:3',
      text:
          'From the rising of the sun unto the going down of the same the LORD’s name is to be praised.',
    ),
    (
      ref: 'Colossians 3:1-2',
      text:
          'If ye then be risen with Christ, seek those things which are above, where Christ sitteth on the right hand of God. Set your affection on things above, not on things on the earth.',
    ),
    (
      ref: 'Isaiah 60:1',
      text:
          'Arise, shine; for thy light is come, and the glory of the LORD is risen upon thee.',
    ),
    (
      ref: 'John 13:35',
      text:
          'By this shall all men know that ye are my disciples, if ye have love one to another.',
    ),
    (
      ref: 'Psalm 116:1-2',
      text:
          'I love the LORD, because he hath heard my voice and my supplications. Because he hath inclined his ear unto me, therefore will I call upon him as long as I live.',
    ),
    (
      ref: 'Colossians 4:6',
      text:
          'Let your speech be alway with grace, seasoned with salt, that ye may know how ye ought to answer every man.',
    ),
    (
      ref: 'Isaiah 64:8',
      text:
          'But now, O LORD, thou art our father; we are the clay, and thou our potter; and we all are the work of thy hand.',
    ),
    (
      ref: 'John 14:2-3',
      text:
          'In my Father’s house are many mansions: if it were not so, I would have told you. I go to prepare a place for you. And if I go and prepare a place for you, I will come again, and receive you unto myself; that where I am, there ye may be also.',
    ),
    (
      ref: 'Psalm 118:8',
      text: 'It is better to trust in the LORD than to put confidence in man.',
    ),
    (
      ref: '1 Thessalonians 5:11',
      text:
          'Wherefore comfort yourselves together, and edify one another, even as also ye do.',
    ),
    (
      ref: 'Jeremiah 31:3',
      text:
          'The LORD hath appeared of old unto me, saying, Yea, I have loved thee with an everlasting love: therefore with lovingkindness have I drawn thee.',
    ),
    (ref: 'John 14:15', text: 'If ye love me, keep my commandments.'),
    (
      ref: 'Psalm 119:9',
      text:
          'Wherewithal shall a young man cleanse his way? by taking heed thereto according to thy word.',
    ),
    (
      ref: '2 Thessalonians 3:3',
      text:
          'But the Lord is faithful, who shall stablish you, and keep you from evil.',
    ),
    (
      ref: 'Hosea 12:6',
      text:
          'Therefore turn thou to thy God: keep mercy and judgment, and wait on thy God continually.',
    ),
    (
      ref: 'John 14:26',
      text:
          'But the Comforter, which is the Holy Ghost, whom the Father will send in my name, he shall teach you all things, and bring all things to your remembrance, whatsoever I have said unto you.',
    ),
    (
      ref: 'Psalm 119:130',
      text:
          'The entrance of thy words giveth light; it giveth understanding unto the simple.',
    ),
    (
      ref: '1 Timothy 4:12',
      text:
          'Let no man despise thy youth; but be thou an example of the believers, in word, in conversation, in charity, in spirit, in faith, in purity.',
    ),
    (
      ref: 'Joel 2:25',
      text:
          'And I will restore to you the years that the locust hath eaten, the cankerworm, and the caterpiller, and the palmerworm, my great army which I sent among you.',
    ),
    (
      ref: 'John 15:16',
      text:
          'Ye have not chosen me, but I have chosen you, and ordained you, that ye should go and bring forth fruit, and that your fruit should remain: that whatsoever ye shall ask of the Father in my name, he may give it you.',
    ),
    (
      ref: 'Psalm 125:1-2',
      text:
          'They that trust in the LORD shall be as mount Zion, which cannot be removed, but abideth for ever. As the mountains are round about Jerusalem, so the LORD is round about his people from henceforth even for ever.',
    ),
    (
      ref: '1 Timothy 6:6',
      text: 'But godliness with contentment is great gain.',
    ),
    (
      ref: 'Habakkuk 3:17-18',
      text:
          'Although the fig tree shall not blossom, neither shall fruit be in the vines; the labour of the olive shall fail, and the fields shall yield no meat; the flock shall be cut off from the fold, and there shall be no herd in the stalls: Yet I will rejoice in the LORD, I will joy in the God of my salvation.',
    ),
    (
      ref: 'John 16:24',
      text:
          'Hitherto have ye asked nothing in my name: ask, and ye shall receive, that your joy may be full.',
    ),
    (
      ref: 'Psalm 127:1',
      text:
          'Except the LORD build the house, they labour in vain that build it: except the LORD keep the city, the watchman waketh but in vain.',
    ),
    (
      ref: 'Hebrews 10:24-25',
      text:
          'And let us consider one another to provoke unto love and to good works: Not forsaking the assembling of ourselves together, as the manner of some is; but exhorting one another: and so much the more, as ye see the day approaching.',
    ),
    (
      ref: 'Isaiah 41:13',
      text:
          'For I the LORD thy God will hold thy right hand, saying unto thee, Fear not; I will help thee.',
    ),
    (
      ref: 'John 17:3',
      text:
          'And this is life eternal, that they might know thee the only true God, and Jesus Christ, whom thou hast sent.',
    ),
    (
      ref: 'Psalm 133:1',
      text:
          'Behold, how good and how pleasant it is for brethren to dwell together in unity!',
    ),
    (
      ref: 'Hebrews 11:6',
      text:
          'But without faith it is impossible to please him: for he that cometh to God must believe that he is, and that he is a rewarder of them that diligently seek him.',
    ),
    (
      ref: 'Acts 1:8',
      text:
          'But ye shall receive power, after that the Holy Ghost is come upon you: and ye shall be witnesses unto me both in Jerusalem, and in all Judæa, and in Samaria, and unto the uttermost part of the earth.',
    ),
    (
      ref: 'Psalm 139:23-24',
      text:
          'Search me, O God, and know my heart: try me, and know my thoughts: And see if there be any wicked way in me, and lead me in the way everlasting.',
    ),
    (
      ref: 'Hebrews 13:5-6',
      text:
          'Let your conversation be without covetousness; and be content with such things as ye have: for he hath said, I will never leave thee, nor forsake thee. So that we may boldly say, The Lord is my helper, and I will not fear what man shall do unto me.',
    ),
    (
      ref: 'Revelation 1:8',
      text:
          'I am Alpha and Omega, the beginning and the ending, saith the Lord, which is, and which was, and which is to come, the Almighty.',
    ),
    (
      ref: 'Psalm 141:3',
      text: 'Set a watch, O LORD, before my mouth; keep the door of my lips.',
    ),
    (
      ref: 'James 3:17',
      text:
          'But the wisdom that is from above is first pure, then peaceable, gentle, and easy to be intreated, full of mercy and good fruits, without partiality, and without hypocrisy.',
    ),
    (
      ref: 'Psalm 143:8',
      text:
          'Cause me to hear thy lovingkindness in the morning; for in thee do I trust: cause me to know the way wherein I should walk; for I lift up my soul unto thee.',
    ),
    (
      ref: 'James 5:16',
      text:
          'Confess your faults one to another, and pray one for another, that ye may be healed. The effectual fervent prayer of a righteous man availeth much.',
    ),
    (
      ref: 'Psalm 150:6',
      text:
          'Let every thing that hath breath praise the LORD. Praise ye the LORD.',
    ),
    (
      ref: '1 John 3:1',
      text:
          'Behold, what manner of love the Father hath bestowed upon us, that we should be called the sons of God: therefore the world knoweth us not, because it knew him not.',
    ),
    (
      ref: '1 John 3:18',
      text:
          'My little children, let us not love in word, neither in tongue; but in deed and in truth.',
    ),
    (
      ref: '1 John 4:7',
      text:
          'Beloved, let us love one another: for love is of God; and every one that loveth is born of God, and knoweth God.',
    ),
    (ref: '1 John 4:19', text: 'We love him, because he first loved us.'),
    (
      ref: '1 John 5:4',
      text:
          'For whatsoever is born of God overcometh the world: and this is the victory that overcometh the world, even our faith.',
    ),
    (
      ref: 'Jude 1:24-25',
      text:
          'Now unto him that is able to keep you from falling, and to present you faultless before the presence of his glory with exceeding joy, To the only wise God our Saviour, be glory and majesty, dominion and power, both now and ever. Amen.',
    ),
  ];
}
