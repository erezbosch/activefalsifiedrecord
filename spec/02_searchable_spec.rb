require '02_searchable'

describe 'Searchable' do
  before(:each) { DBConnection.reset }
  after(:each) { DBConnection.reset }

  before(:all) do
    class Cat < SQLObject
      finalize!
    end

    class Human < SQLObject
      self.table_name = 'humans'

      finalize!
    end
  end

  describe '#where' do
    it 'searches with single criterion' do
      cats = Cat.where(name: 'Breakfast')
      cat = cats.first

      expect(cats.length).to eq(1)
      expect(cat.name).to eq('Breakfast')
    end

    it 'can return multiple objects' do
      humans = Human.where(house_id: 1)
      expect(humans.length).to eq(2)
    end

    it 'searches with multiple criteria' do
      humans = Human.where(fname: 'Matt', house_id: 1)
      expect(humans.length).to eq(1)

      human = humans[0]
      expect(human.fname).to eq('Matt')
      expect(human.house_id).to eq(1)
    end

    it 'comes up empty if nothing matches the criteria' do
      expect(Human.where(fname: 'Nowhere', lname: 'Man')).to be_empty
    end

    it 'stacks' do
      haskells = Cat.where(owner_id: 3).where(name: 'Haskell')
      expect(haskells.first.id).to eq(3)
    end

    it 'double-stacks' do
      matts = Human.where(fname: 'Matt').where(house_id: 1).where(id: 2)
      expect(matts.first.lname).to eq("Rubens")
    end
  end
end
