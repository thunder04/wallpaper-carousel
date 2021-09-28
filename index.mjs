import { constants as fsConstants } from "fs"
import fs from 'fs/promises'
import req from 'petitio'

//MAKE last_sweep_time.timestamp file indicating the last time a sweep happened -> sweep: Delete all files older than X time

// ! Constants ! 

const LISTING_TYPES = [ 'controversial', 'best', 'hot', 'new', 'random', 'rising', 'top' ]
const TIMEFRAME_TYPES = [ 'hour', 'day', 'week', 'month', 'year', 'all' ]
const DEFAULT_SUBREDDITS = [
    // 'WidescreenWallpaper',
    'Amoledbackgrounds',
    'wallpapers',
    'wallpaper',
]

// ! Helper functions ! 

function schedule(callback, ms, ...args) {
    if (ms > 0x7FFFFFFF) return setTimeout(() => schedule(callback, ms - 0x7FFFFFFF, ...args), 0x7FFFFFFF)
    return setTimeout(callback, ms, ...args)
}

function hashFileName(str) {
    var hval = 0x811c9dc5

    for (const char of str) {
        hval ^= char.charCodeAt(0)
        hval += (hval << 1) + (hval << 4) + (hval << 7) + (hval << 8) + (hval << 24)
    }

    return hval >>> 0
}

/**
 * @param aliases {Record<string, string[]>}
 * @returns {Record<string, boolean | string>}
 */
function parseArguments(argv, aliases) {
    const res = {}

    for (var arg of argv) {
        if (arg.startsWith('--')) arg = arg.slice(2)
        else if (arg.startsWith('-')) arg = arg.slice(1)
        else continue

        var [ key, value ] = arg.split('=')

        if (!(key in aliases)) {
            let found = false

            for (const prop in aliases) {
                if (aliases[ prop ].includes(key)) {
                    found = true
                    key = prop
                    break
                }
            }

            if (!found) continue
        }

        res[ key ] = value ?? true
    }

    return new Proxy(res, { get: (obj, k) => k in obj ? obj[ k ] : null })
}

/** 
 * @param subreddit {string} The subreddit to fetch from
 */
async function fetchSubreddit(subreddit, limit = -1) {
    const url = new URL(`https://www.reddit.com/r/${subreddit}.json?listing=${listing}&t=${timeframe}`)
    if (limit > 0) url.searchParams.append('limit', limit)

    return req(url).send()
}

const argv = parseArguments(process.argv.slice(2), {
    /** Sweeping and fetching interval. In minutes */
    interval: [ 'time', 't' ],
    /** Lifetime of an image. In days */
    lifetime: [ 'lt' ],

    wallpaper_folder: [ 'w', 'wf' ],
    subreddits: [ 'sub', 's' ],
    timeframe: [ 'tf' ],
    listing: [ 'l' ],
})

// ! Argument parsing ! 

const subreddits = typeof argv.subreddits === 'string' ? argv.subreddits.split(/,+/g) : DEFAULT_SUBREDDITS
    , lifetime = (+argv.lifetime || 4) * 86_400_000
    , interval = (+argv.interval || 60) * 60_000
    , wallpaperFolder = argv.wallpaper_folder
    , timeframe = argv.timeframe || 'all'
    , listing = argv.listing || 'hot'

// ! Argument validation !

if (wallpaperFolder) {
    try {
        await fs.access(wallpaperFolder, fsConstants.R_OK | fsConstants.W_OK)
    } catch {
        throw new Error(`Cannot access "${wallpaperFolder}". Make sure I have permissions to read & write to the folder.`)
    }

    if (!(await fs.stat(wallpaperFolder)).isDirectory()) throw new Error(`"${wallpaperFolder}" isn't a directory.`)
} else throw new Error('The --wallpaper_folder argument is required.')

if (!TIMEFRAME_TYPES.includes(timeframe)) throw new TypeError(`Unknown timeframe type "${timeframe}".`)
if (!LISTING_TYPES.includes(listing)) throw new TypeError(`Unknown listing type "${listing}".`)

// ! Start of the script !

console.log({ subreddits, lifetime, interval, timeframe, listing, wallpaperFolder })