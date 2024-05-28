import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { web3, setupContract, hotelBooking } from '../utils/web3';
import ipfs from '../utils/ipfs';

const BookingForm = () => {
    const { roomId } = useParams(); // URL 파라미터에서 roomId를 가져옴
    const [checkInDate, setCheckInDate] = useState(''); // 체크인 날짜 상태
    const [checkOutDate, setCheckOutDate] = useState(''); // 체크아웃 날짜 상태
    const [userName, setUserName] = useState(''); // 사용자 이름 상태
    const [userEmail, setUserEmail] = useState(''); // 사용자 이메일 상태
    const [contractReady, setContractReady] = useState(false); // 스마트 계약 준비 상태

    useEffect(() => {
        // 스마트 계약을 초기화하는 함수
        const initContract = async () => {
            await setupContract(); // 계약 설정 함수 호출
            setContractReady(true); // 계약 준비 상태를 true로 설정
        };

        initContract(); // 컴포넌트가 마운트될 때 계약 초기화
    }, []);

    // 방 예약 처리 함수
    const handleBooking = async () => {
        if (!contractReady) { // 계약이 준비되지 않은 경우
            alert("Contract is not ready yet. Please try again later."); // 알림 메시지 표시
            return;
        }

        try {
            const accounts = await web3.eth.getAccounts(); // 사용자의 계정 가져오기
            const account = accounts[0]; // 첫 번째 계정 사용

            console.log("Account: ", account);
            console.log("Room ID: ", roomId);
            console.log("Check-in Date: ", checkInDate);
            console.log("Check-out Date: ", checkOutDate);

            // 사용자 정보를 IPFS에 저장 (임의로 지정한 값 사용)
            const userInfo = {
                name: "John Doe",
                email: "john.doe@example.com",
            };
            console.log("User Info: ", userInfo);
            const added = await ipfs.add(JSON.stringify(userInfo)); // IPFS에 사용자 정보 추가
            const ipfsHash = added.path; // IPFS 해시 가져오기
            console.log("IPFS Hash: ", ipfsHash);

            // 날짜를 Unix 타임스탬프로 변환
            const checkInTimestamp = Math.floor(new Date(checkInDate).getTime() / 1000);
            const checkOutTimestamp = Math.floor(new Date(checkOutDate).getTime() / 1000);

            const room = await hotelBooking.methods.rooms(roomId).call(); // 방 정보 가져오기
            console.log("Room: ", room);
            const price = room.price; // 방 가격 가져오기
            console.log("Room Price: ", price);

            // 현재 가스 가격 가져오기
            const gasPrice = await web3.eth.getGasPrice();
            console.log("Gas Price: ", gasPrice);

            // 스마트 계약 함수 호출
            await hotelBooking.methods.bookRoom(roomId, checkInTimestamp, checkOutTimestamp)
                .send({ from: account, value: price, gasPrice });

            alert('Room booked successfully! Your information hash is: ' + ipfsHash); // 예약 성공 메시지 표시
        } catch (error) {
            console.error("Error during booking:", error);
            alert("Error during booking. See console for details."); // 예약 중 오류 발생 시 메시지 표시
        }
    };

    return (
        <div>
            <h2>Book a Room</h2>
            <p>Room ID: {roomId}</p>
            <input
                type="text"
                placeholder="Name"
                value={userName}
                onChange={e => setUserName(e.target.value)} // 사용자 이름 입력 처리
            />
            <input
                type="email"
                placeholder="Email"
                value={userEmail}
                onChange={e => setUserEmail(e.target.value)} // 사용자 이메일 입력 처리
            />
            <input
                type="date"
                placeholder="Check-in Date"
                value={checkInDate}
                onChange={e => setCheckInDate(e.target.value)} // 체크인 날짜 입력 처리
            />
            <input
                type="date"
                placeholder="Check-out Date"
                value={checkOutDate}
                onChange={e => setCheckOutDate(e.target.value)} // 체크아웃 날짜 입력 처리
            />
            <button onClick={handleBooking}>Book</button> // 예약 버튼 클릭 시 handleBooking 함수 호출
        </div>
    );
};

export default BookingForm;
