#! /usr/bin/env python3

# eicdesk01_bot

import os.path

from telegram import Update
from telegram.ext import Updater, CommandHandler, CallbackContext

def hello(update: Update, context: CallbackContext) -> None:
    update.message.reply_text(f'Hello {update.effective_user.first_name}')

def memmert(update: Update, context: CallbackContext) -> None:
    tag = '2h'
    if len(context.args) == 1:
        tag = context.args[0]
    filename = '/home/eic/DATA/memmert/PNG/draw_memmert_' + tag + '.png'
    if not os.path.isfile(filename):
        return
    file = open(filename, 'rb')
    update.message.reply_photo(photo=file)

        

updater = Updater('5193574312:AAHWltxpUQQZtzffp2WoVgZ5n50eipQ7JDo')

updater.dispatcher.add_handler(CommandHandler('hello', hello))
updater.dispatcher.add_handler(CommandHandler('memmert', memmert))

updater.start_polling()
updater.idle()

