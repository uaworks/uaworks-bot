require('dotenv').config()
const notion = require('./notion')
const telegram = require('./telegram')

module.exports.publishJobs = async () => {    
    console.info("Publishing new jobs")
    
    const jobs = await notion.fetchNewJobs()    
    telegram.publishToChannel(jobs)    
    notion.markAsPublished(jobs)

    console.info(`Published ${jobs.length} jobs`)
}

