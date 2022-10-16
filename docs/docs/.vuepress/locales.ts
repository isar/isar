export interface LocalConfig {
  locale: string;
  language: string;
  selectLanguage: string;
  editPage: string;
  lastUpdated: string;
  tip: string;
  warning: string;
  danger: string;
  notFound: string[];
  backToHome: string;
  translationOutdated: string;

  dbName: string;
  dbDescription: string;

  tutorials: string;
  concepts: string;
  recipes: string;
  sampleApps: string;
  changelog: string;
  contributors: string;
}

export function getLocalePath(locale: string): string {
  const localeName = locale.split("-")[0];
  if (localeName === "en") {
    return "/";
  } else {
    return "/" + localeName + "/";
  }
}

export const locales: LocalConfig[] = [
  {
    locale: "en-US",
    language: "English",
    selectLanguage: "Select Language",
    editPage: "Edit Page",
    lastUpdated: "Last Updated",
    tip: "Tip",
    warning: "Warning",
    danger: "Danger",
    notFound: [
      "Nothing to see here.",
      "How did we end up here?",
      "This is a four-oh-four...",
      "Looks like we have a broken link.",
    ],
    backToHome: "Back to Home",
    translationOutdated: "Translation is outdated. Please help us update it!",
    dbName: "Isar Database",
    dbDescription: "Super Fast Cross-Platform Database for Flutter",
    tutorials: "TUTORIALS",
    concepts: "CONCEPTS",
    recipes: "RECIPES",
    sampleApps: "Sample Apps",
    changelog: "Changelog",
    contributors: "Contributors",
  },
  {
    locale: "de-DE",
    language: "Deutsch",
    selectLanguage: "Sprache wählen",
    editPage: "Seite bearbeiten",
    lastUpdated: "Zuletzt aktualisiert",
    tip: "Tipp",
    warning: "Warnung",
    danger: "Achtung",
    notFound: [
      "Hier gibt es nichts zu sehen.",
      "Wie sind wir hier gelandet?",
      "Das ist ein vier-null-vier...",
      "Sieht aus als hätten wir einen kaputten Link.",
    ],
    backToHome: "Zurück zur Startseite",
    translationOutdated:
      "Übersetzung ist veraltet. Bitte hilf uns, sie zu aktualisieren!",
    dbName: "Isar Datenbank",
    dbDescription: "Super Schnelle Cross-Platform Flutter Datenbank",
    tutorials: "TUTORIALS",
    concepts: "KONZEPTE",
    recipes: "REZEPTE",
    sampleApps: "Beispiel Apps",
    changelog: "Änderungsprotokoll",
    contributors: "Mitwirkende",
  },
  {
    locale: "ja-JP",
    language: "日本語",
    selectLanguage: "言語の選択",
    editPage: "編集ページ",
    lastUpdated: "最終更新日",
    tip: "ヒント",
    warning: "警告",
    danger: "危険",
    notFound: [
      "何も見つかりませんでした.",
      "どうしてこんなところに辿り着いたのだろう...",
      "ここは404ページのようです...",
      "リンク切れのようです。",
    ],
    backToHome: "ホームに戻る",
    translationOutdated:
      "翻訳は古くなっています。翻訳の更新にご協力頂けませんか？",
    dbName: "Isar Database",
    dbDescription: "Flutterのための超高速クロスプラットフォームDatabase",
    tutorials: "チュートリアル",
    concepts: "コンセプト",
    recipes: "レシピ集",
    sampleApps: "サンプルアプリ",
    changelog: "変更履歴",
    contributors: "貢献者の方々",
  },
  {
    locale: "es-AR",
    language: "Español",
    selectLanguage: "Seleccionar Idioma",
    editPage: "Editar Página",
    lastUpdated: "Última actualización",
    tip: "Consejo",
    warning: "Advertencia",
    danger: "Peligro",
    notFound: [
      "No hay nada para ver aquí.",
      "Cómo llegamos aquí?",
      "Esto es vergonzoso, no tenemos nada...",
      "Parece que hay un enlace roto.",
    ],
    backToHome: "Volver al inicio",
    translationOutdated:
      "Esta traducción está desactualizada. Por favor ayúdanos a mantenerla al día!",
    dbName: "Isar Database",
    dbDescription: "Base de Datos Super rápida, Multiplataforma para Flutter",
    tutorials: "TUTORIALES",
    concepts: "CONCEPTOS",
    recipes: "RECETAS",
    sampleApps: "Aplicaciones de Ejemplo",
    changelog: "Registro de cambios",
    contributors: "Colaboradores",
  },
  {
    locale: "it-IT",
    language: "Italiano",
    selectLanguage: "Seleziona Lingua",
    editPage: "Modifica Pagina",
    lastUpdated: "Ultimo aggiornamento",
    tip: "Suggerimento",
    warning: "Attenzione",
    danger: "Pericolo",
    notFound: [
      "Nulla da vedere qui.",
      "Come ci siamo finiti qui?",
      "Questa è una quattro-zero-quattro...",
      "Sembra che abbiamo un collegamento rotto.",
    ],
    backToHome: "Indietro alla Home",
    translationOutdated:
      "La traduzione è obsoleta. Per favore aiutaci ad aggiornarla!",
    dbName: "Isar Database",
    dbDescription: "Database multipiattaforma super veloce per Flutter",
    tutorials: "TUTORIALS",
    concepts: "CONCETTI",
    recipes: "RICETTE",
    sampleApps: "App d'esempio",
    changelog: "Registro delle modifiche",
    contributors: "Contributori",
  },
];
