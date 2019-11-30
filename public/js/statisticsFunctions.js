//* https://stackoverflow.com/questions/1484506/random-color-generator
function getRandomColor() {
  var letters = '0123456789ABCDEF';
  var color = '#';
  for (var i = 0; i < 6; i++) {
    color += letters[Math.floor(Math.random() * 16)];
  }
  return color;
}
class Program{
  constructor (name, validLabels){
    this.name = name
    this.validLabels = validLabels
    this.quantity = 0
    this.default = false
  }

  checkName (name) {
    return name && this.validLabels.includes(name.toLowerCase())
  }
  isDefault () {
    return this.default
  }

  static generateDefault (name) {
    const instance = new Program(name, [])
    instance.default = true
    return instance
  }
}
function generateStandardData () {
  return [
    {
      name: 'M',
      validLabels: [
        'm', 'maskin'
      ],
    },
    {
      name: 'I',
      validLabels: [
        'i'
      ]
    },
    {
      name: 'Y',
      validLabels: [
        'y'
      ],
    },
    {
      name: 'MatNat',
      validLabels: [
        'matnat', 'mt'
      ],
    },
    {
      name: 'TBI',
      validLabels: [
        'tbi', 'tb'
      ],
    },
    {
      name: 'D & C',
      validLabels: [
        'd', 'c', 'it'
      ],
    },
    {
      name: 'Ling',
      validLabels: [
        'ling'
      ],
    }
  ].map(info => {
    return new Program(info.name, info.validLabels)
  }).concat(Program.generateDefault('Okänd'))
}

function generateStandardCities () {
  return [
    {
      name: 'Östergötland',
      validLabels: [
        'linköping',
        'motala',
        'nyköping',
        'vreta',
        'norrköping'
      ],
    },
    {
      name: 'Stockholms län',
      validLabels: [
        'stockholm',
        'bromma',
        'täby',
        'sollentuna',
        'hägersten',
        'lidingö',
        'hässelby',
        'huddinge'
      ] 
    },
    {
      name: 'Västmanland',
      validLabels: [
        'västerås'
      ]
    },
    {
      name: 'södermanland',
      validLabels: [
        'södertälje'
      ]
    },
    {
      name: 'Skåne län',
      validLabels: [
        'malmö'
      ],
    },
    {
      name: 'Jönköping',
      validLabels: [
        'jönköping'
      ]
    },
    {
      name: 'Västra götaland',
      validLabels: [
        'göteborg',
        'torslanda',
        'trollhättan'
      ],
    },
    {
      name: 'Uppsala',
      validLabels: [
        'uppsala'
      ]
    }
  ].map(info => {
    return new Program(info.name, info.validLabels)
  }).concat(Program.generateDefault('Övrigt'))
}

function preprocessProgramData(programs, standardisedData) {
  programs.forEach((program) => {
    const {name, quantity} = program
    const programInStandardisedData = standardisedData.find((program => {
      return program.checkName(name)
    }))
    const programToIncrease = programInStandardisedData !== undefined 
     ? programInStandardisedData
     : standardisedData.find(program => program.isDefault())

    programToIncrease.quantity += quantity
  })
  return standardisedData
}
function sortOnname (data) {
  return data.sort((a, b) => {
    return a.name > b.name
  })
}

function sortOnQuantity (data) {
  return data.sort((a, b) => {
    return a.quantity > b.quantity
  })
}
function drawStarted(ctx, years) {
  years = sortOnname(years)

  years.forEach(a => {
    if(a.name === null) {
      a.name = 'Unknown'
    }
  })
  addDataToChart(years, ctx, 'bar')
}

function drawStudied(ctx, programs) {
  programs = preprocessProgramData(programs, generateStandardData())
  addDataToChart(programs, ctx, 'doughnut');
}

function drawCity(ctx, cities) {
  console.log('cities', sortOnQuantity(cities).map(a=>a.name).join(','))
  cities = preprocessProgramData(cities, generateStandardCities())
  addDataToChart(cities, ctx, 'bar');
}

function addDataToChart(programs, ctx, type) {
  const labels = programs.map(a => a.name);
  const data = programs.map(a => a.quantity);
  const backgroundColor = data.map(getRandomColor);
  new Chart(ctx, {
    type,
    data: {
      labels,
      datasets: [{
        data,
        backgroundColor
      }]
    }
  });
}

