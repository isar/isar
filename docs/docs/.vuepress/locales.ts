export interface LocalConfig {
    locale: string
    language: string
    selectLanguage: string
    editPage: string
    lastUpdated: string
    tip: string
    warning: string
    danger: string
    notFound: string[]
    backToHome: string
    translationOutdated: string

    dbName: string
    dbDescription: string

    tutorials: string
    concepts: string
    recipes: string
    sampleApps: string
    changelog: string
    contributors: string
}

export function getLocalePath(locale: string): string {
    const localeName = locale.split('-')[0]
    if (localeName === 'en') {
        return '/'
    } else {
        return '/' + localeName + '/'
    }
}

export const locales: LocalConfig[] = [
    {
        locale: 'en-US',
        language: 'English',
        selectLanguage: 'Select Language',
        editPage: 'Edit Page',
        lastUpdated: 'Last Updated',
        tip: 'Tip',
        warning: 'Warning',
        danger: 'Danger',
        notFound: [
            'Nothing to see here.',
            'How did we end up here?',
            'This is a four-oh-four...',
            'Looks like we have a broken link.',
        ],
        backToHome: 'Back to Home',
        translationOutdated: 'Translation is outdated. Please help us update it!',
        dbName: 'Isar Database',
        dbDescription: 'Super Fast Cross-Platform Database for Flutter',
        tutorials: 'TUTORIALS',
        concepts: 'CONCEPTS',
        recipes: 'RECIPES',
        sampleApps: 'Sample Apps',
        changelog: 'Changelog',
        contributors: 'Contributors',
    },
    {
        locale: 'de-DE',
        language: 'Deutsch',
        selectLanguage: 'Sprache wählen',
        editPage: 'Seite bearbeiten',
        lastUpdated: 'Zuletzt aktualisiert',
        tip: 'Tipp',
        warning: 'Warnung',
        danger: 'Achtung',
        notFound: [
            'Hier gibt es nichts zu sehen.',
            'Wie sind wir hier gelandet?',
            'Das ist ein vier-null-vier...',
            'Sieht aus als hätten wir einen kaputten Link.',
        ],
        backToHome: 'Zurück zur Startseite',
        translationOutdated: 'Übersetzung ist veraltet. Bitte hilf uns, sie zu aktualisieren!',
        dbName: 'Isar Datenbank',
        dbDescription: 'Super Schnelle Cross-Platform Flutter Datenbank',
        tutorials: 'TUTORIALS',
        concepts: 'KONZEPTE',
        recipes: 'REZEPTE',
        sampleApps: 'Beispiel Apps',
        changelog: 'Änderungsprotokoll',
        contributors: 'Mitwirkende',
    }
]