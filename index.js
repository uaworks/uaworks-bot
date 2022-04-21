require('dotenv').config()
const notion = require('./notion')
const telegram = require('./telegram')
const cron = require('node-cron');

publishJobs = async () => {    
    console.info("Publishing new jobs")
    
    jobs = await notion.fetchNewJobs()    
    telegram.publishToChannel(jobs)    
    notion.markAsPublished(jobs)

    console.info(`Published ${jobs.length} jobs`)
}

//every 3 hours
var pubTask = cron.schedule('0 0 */3 * * *', publishJobs)
pubTask.start()

process.once('SIGINT', () => {
    pubTask.stop()
})

process.once('SIGTERM', () => {    
    pubTask.stop()
})
