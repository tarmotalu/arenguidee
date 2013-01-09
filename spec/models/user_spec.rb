# -*- encoding : utf-8 -*-
require 'spec_helper'

describe User, '#apply_omniauth' do
  before do
    subject { FactoryGirl.build(:user) }
    subject.apply_omniauth('user_info' => {'first_name' => first_name, 'last_name' => last_name, 'personal_code' => 'my_id', 'email' => 'me@somwhere.com'})
  end
  
  let(:first_name) { 'FOO' }
  let(:last_name) { 'BAR' }
  
  it 'humanizes first name' do
    subject.first_name.should == 'Foo'
  end
  
  it 'humanizes last name' do
    subject.last_name.should == 'Bar'
  end
  
  it 'sets login' do
    subject.login.should == 'my_id'
  end
  
  it 'sets email' do
    subject.email.should == 'me@somwhere.com'
  end
  
  it 'sets status' do
    subject.status.should == 'active'
  end
  
  context 'when name starts with multibyte' do
    let(:first_name) { 'ÜLLE' }
    
    it 'humanizes first name' do
      subject.first_name.should == 'Ülle'
    end
  end

  context 'when name contains multibyte' do
    let(:first_name) { 'PÕDER' }
    
    it 'humanizes first name' do
      subject.first_name.should == 'Põder'
    end
  end

  context 'when name of compound' do
    let(:first_name) { 'MARI-ÕIS' }
    
    it 'humanizes first name' do
      subject.first_name.should == 'Mari-Õis'
    end
  end
end