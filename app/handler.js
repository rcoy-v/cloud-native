module.exports = async (event, context) => context.status(200).succeed({message: 'Automate all the things!', timestamp: Date.now()});
