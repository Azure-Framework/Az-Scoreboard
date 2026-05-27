Config = {}

Config.FrameworkResource = 'Az-Framework'
Config.OpenKey = 213
Config.Command = 'scoreboard'
Config.Debug = false
Config.WebhookURL = ''

Config.UI = {
  fontFamily = 'Arial, sans-serif',
  title = 'AZURE SCRIPTS',
  subtitle = 'SCOREBOARD',
  directoryTitle = 'PLAYER DIRECTORY',
  directorySubtitle = 'Live roster and department counts.',
  statusText = 'Ready',
  sectionTitle = 'Roster',
  stampTitle = 'AZURE',
  stampSubtitle = 'SCOREBOARD',
  closeLabel = 'Close'
}

Config.Tabs = {
  {
    id = 'players',
    label = 'Players',
    showAll = true,
    showInFooter = false,
    jobs = {},
    color = 'rgba(42,164,216,.95)',
    glow = 'rgba(42,164,216,.12)'
  },
  {
    id = 'police',
    label = 'Police',
    badgeLabel = 'Police',
    jobs = { 'police', 'sheriff', 'state', 'trooper' },
    color = 'rgba(60,120,255,.95)',
    glow = 'rgba(60,120,255,.12)'
  },
  {
    id = 'medics',
    label = 'Medics',
    badgeLabel = 'Medics',
    jobs = { 'ambulance', 'medic', 'ems', 'doctor' },
    color = 'rgba(60,220,120,.95)',
    glow = 'rgba(60,220,120,.12)'
  },
  {
    id = 'mechanic',
    label = 'Mechanic',
    badgeLabel = 'Mechanic',
    jobs = { 'mechanic' },
    color = 'rgba(255,180,60,.95)',
    glow = 'rgba(255,180,60,.12)'
  }
}
