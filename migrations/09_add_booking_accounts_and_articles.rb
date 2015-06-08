Sequel.migration do
  up do
    self[:booking_accounts].insert(name: 'Medlemstransaktioner'     , number: 2021)
    self[:booking_accounts].insert(name: 'Plusgiro'                 , number: 1920)
    self[:booking_accounts].insert(name: 'Kontantkassa'             , number: 1910)
    self[:booking_accounts].insert(name: 'Fest 2005'                , number: 7320)
    self[:booking_accounts].insert(name: 'Inköp'                    , number: 4010)
    self[:booking_accounts].insert(name: 'Sångböcker'               , number: 3021)
    self[:booking_accounts].insert(name: 'Medaljer'                 , number: 3022)
    self[:booking_accounts].insert(name: 'Porto'                    , number: 6250)
    self[:booking_accounts].insert(name: 'Intäkter Vårarbetslunch'  , number: 3001)
    self[:booking_accounts].insert(name: 'Intäkter Höstarbetslunch' , number: 3002)
    self[:booking_accounts].insert(name: 'Intäkter Vårfest'         , number: 3003)
    self[:booking_accounts].insert(name: 'Intäkter Höstfest'        , number: 3004)
    self[:booking_accounts].insert(name: 'Inköp Vårarbetslunch'     , number: 4001)
    self[:booking_accounts].insert(name: 'Inköp Höstarbetslunch'    , number: 4002)
    self[:booking_accounts].insert(name: 'Inköp Vårfest'            , number: 4003)
    self[:booking_accounts].insert(name: 'Inköp Höstfest'           , number: 4004)

    self[:articles].insert(name: 'Öl')
    self[:articles].insert(name: 'Snaps')
    self[:articles].insert(name: 'Läsk')
    self[:articles].insert(name: 'Sångbok')
    self[:articles].insert(name: 'Avec')
    self[:articles].insert(name: 'Strecköl')
    self[:articles].insert(name: 'Cider')
    self[:articles].insert(name: 'Korv')
    self[:articles].insert(name: 'Anm')
    self[:articles].insert(name: 'Vin')
  end

  down do
    self[:booking_accounts].delete
    self[:articles].delete
  end
end
