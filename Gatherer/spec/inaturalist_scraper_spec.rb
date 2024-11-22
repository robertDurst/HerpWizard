require 'rspec'
require_relative '../../Gatherer/src/inaturalist_scraper'

RSpec.describe Helper do
  it 'foobars an empty set' do
    actual = Helper.filter([])
    expected = []

    expect(actual).to eq(expected)
  end

  it 'foobars a set with one element' do
    actual = Helper.filter([1])
    expected = [
      { ok: true, value: 1 }
    ]

    expect(actual).to eq(expected)
  end

  it 'foobars a simple set' do
    actual = Helper.filter([1, 2, 3, 4, 5])
    expected = [
      { ok: true, value: 1 },
      { ok: true, value: 2 },
      { ok: true, value: 3 },
      { ok: true, value: 4 },
      { ok: true, value: 5 }
    ]

    expect(actual).to eq(expected)
  end

  it 'foobars more complex' do
    actual = Helper.filter([1, 200, 3, 500, 20, 50, 30_000])
    expected = [
      { ok: true, value: 1 },
      { ok: false, value: 200 },
      { ok: true, value: 3 },
      { ok: false, value: 500 },
      { ok: true, value: 20 },
      { ok: true, value: 50 },
      { ok: false, value: 30_000 }
    ]

    expect(actual).to eq(expected)
  end

  it 'deciphers an empty list' do
    actual = Helper.decipher([])
    expected = [[], nil]

    expect(actual).to eq(expected)
  end

  it 'deciphers a list with one ok element' do
    actual = Helper.decipher([{ ok: true, value: 1 }])
    expected = [[], 1]

    expect(actual).to eq(expected)
  end

  it 'deciphers a list with one not ok element' do
    actual = Helper.decipher([{ ok: false, value: 1 }])
    expected = [[], nil]

    expect(actual).to eq(expected)
  end

  it 'deciphers a simple list' do
    actual = Helper.decipher([
                               { ok: true, value: 1 },
                               { ok: true, value: 2 },
                               { ok: true, value: 3 },
                               { ok: true, value: 4 },
                               { ok: true, value: 5 }
                             ])
    expected = [[1, 2, 3, 4], 5]

    expect(actual).to eq(expected)
  end

  it 'deciphers a more complex list' do
    actual = Helper.decipher([
                               { ok: true, value: 1 },
                               { ok: false, value: 200 },
                               { ok: true, value: 3 },
                               { ok: false, value: 500 },
                               { ok: true, value: 20 },
                               { ok: true, value: 50 },
                               { ok: false, value: 30_000 }
                             ])
    expected = [[1, 200, 3, 500, 20], 50]

    expect(actual).to eq(expected)
  end
end
